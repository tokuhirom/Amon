use strict;
use warnings;
use utf8;

package Amon2::Setup;
use Data::Section::Simple ();
use Text::Xslate;
use Plack::Util ();
use File::Spec;
use File::Basename;
use File::Path ();
use Amon2;

our $_CURRENT_FLAVOR_NAME;

sub infof {
    my $flavor = $_CURRENT_FLAVOR_NAME || '-';
    $flavor =~ s!^(?:Amon2::Setup::Flavor::|\+)!!;
    print "[$flavor] ";
    @_==1 ? print(@_) : printf(@_);
    print "\n";
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    $args{amon2_version} = $Amon2::VERSION;

    for (qw/module/) {
        die "Missing mandatory parameter $_" unless exists $args{$_};
    }
    $args{module} =~ s!-!::!g;

    # $module = "Foo::Bar"
    # $dist   = "Foo-Bar"
    # $path   = "Foo/Bar"
    my @pkg  = split /::/, $args{module};
    $args{dist} = join "-", @pkg;
    $args{path} = join "/", @pkg;
    my $self = bless { %args }, $class;
    my %files;
    return $self;
}

# $setup->run('Teng', 'Basic')
sub run {
    my ($self, $flavors, $plugins)= @_;

    $self->load_flavors($flavors, $plugins || []);
    $self->run_flavors();
}

sub create_xslate {
    my ($self, @args) = @_;
    my $xslate = Text::Xslate->new(
        syntax => 'Kolon', # for template cascading
        type   => 'text',
        cache => 0,
        @args,
    );
    return $xslate;
}

sub run_flavors {
    my ($self) = @_;

    my @path = @{$self->{flavors}};
    infof("Using flavors " . join(", ", map { $_->[0] } @path));

    # rewrite a path like <<CONTEXT_PATH>>
    my @preprocessed = do {
        my @preprocessed;

        for my $p (@path) {
            my $tmpl = $p->[1];
            my %processed;
            while (my ($x, $dat) = each %$tmpl) {
                $x =~ s!<<(WEB_CONTEXT_PATH|CONTEXT_PATH|CONFIG_(?:DEVELOPMENT|DEPLOYMENT|TEST)_PATH)>>!
                    sub {
                        for my $klass (map { $_->[0] } @path) {
                            if (my $code = $klass->can(lc $1)) {
                                return $code->($klass);
                            }
                        }
                        die "Cannot detect @{[ lc $1 ]} property in flavors : " . join(', ', map { $_->[0] } @path);
                    }->()
                !ge;
                $processed{$x} = $dat;
            }
            push @preprocessed, [$p->[0], \%processed];
        }
        @preprocessed;
    };

    {
        my @pp = @preprocessed;
        my %flavor_seen;
        my %tmpl_seen;
        while (my $p = shift @pp) {
            next if $flavor_seen{$p->[0]};

            local $_CURRENT_FLAVOR_NAME = $p->[0];
            for my $fname (sort { $a cmp $b } keys %{$p->[1]}) {
                next if $tmpl_seen{$fname}++;
                next if $fname =~ /^#/;
                $self->write_file($fname, [$p, @pp]);
            }
        }
    }

    my ($standalone) = grep { $_->can('is_standalone') && $_->is_standalone } map { $_->[0] } @preprocessed;
    if ($standalone->can('load_assets')) {
        infof("Writing assets");
        local $_CURRENT_FLAVOR_NAME = $standalone;
        $standalone->load_assets($self, $self->{assets} || []);
    } else {
        for my $asset (@{ $self->{assets} }) {
            my $files = $asset->files;
            while (my ($fname, $data) = each %$files) {
                $self->write_file_raw("static/$fname", $data);
            }
        }
    }

    for my $flavor (@preprocessed) {
        my $klass = $flavor->[0];
        if ($klass->can('postprocess')) {
            $klass->postprocess();
        }
    }
}

sub write_file {
    my ($self, $fname_tmpl, $thing) = @_;

    my $filtered_tmpl = $fname_tmpl;

    my %cascading_path;
    my @preprocessed =
        map { [ $_->[0], $_->[1]->{$fname_tmpl} ] }
        grep { defined($_->[1]->{$fname_tmpl}) }
        @$thing;
    while (my $it = shift @preprocessed) {
        my $flavor = $it->[0];
        my $tmpl = $it->[1];
        $tmpl =~ s{^:\s*cascade\s+(["'])!\1\s*;?\s*$}{
            my $path = $preprocessed[0]->[0]
                or die "Missing parent template for '$fname_tmpl'";
            ": cascade '$path/$fname_tmpl'\n";
        }em;
        $cascading_path{"$flavor/$fname_tmpl"} = $tmpl;
    }

    my $xslate = $self->create_xslate(
        path => [(map { $_->[1] } @$thing), \%cascading_path],
    );

    my $filename = $fname_tmpl;
    $filename =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;
    my $content = $xslate->render("$thing->[0]->[0]/$fname_tmpl", +{%$self});

    $self->write_file_raw($filename, $content);
}


sub load_flavors {
    my ($self, $flavors, $plugins) = @_;

    my @path;
    for my $plugin (@$plugins) {
        push @path, $self->_load_flavor($plugin, 'Amon2::Plugin');
    }
    for my $flavor (@$flavors) {
        push @path, $self->_load_flavor($flavor, 'Amon2::Setup::Flavor');
    }
    unless (grep { $_->can('is_standalone') && $_->is_standalone } map { $_->[0] } @path) {
        push @path, $self->_load_flavor('Basic', 'Amon2::Setup::Flavor');
    }
    $self->{flavors} = \@path;
}

sub _load_templates {
    my ($self, $klass) = @_;
    my $reader = Data::Section::Simple->new($klass);
    my $all = $reader->get_data_section();
    unless ($all) {
        infof("There is no template: $klass");
    }
    return $all;
}

sub _load_flavor {
    my ($self, $flavor, $namespace) = @_;

    local $_CURRENT_FLAVOR_NAME = $flavor;
    infof("Loading $flavor");
    my $klass = Plack::Util::load_class($flavor, $namespace);
    if ($klass->can('assets')) {
        for my $asset ($klass->assets()) {
            $self->load_asset($asset);
        }
    }
    my $all = $self->_load_templates($klass);

    my @parent;
    if ($klass->can('parent')) {
        for my $parent ($klass->parent()) {
            push @parent, $self->_load_flavor($parent, 'Amon2::Setup::Flavor');
        }
    }
    my @plugins;
    if ($klass->can('plugins')) {
        for my $plugin ($klass->plugins()) {
            push @plugins, $self->_load_flavor($plugin, 'Amon2::Plugin');
        }
    }
    return (@plugins, [$klass, $all], @parent);
}

sub write_file_raw {
    my ($self, $filename, $content) = @_;

    infof("writing $filename");

    if (my $dirname = dirname($filename)) {
        File::Path::mkpath($dirname);
    }

    open my $ofh, '>:utf8', $filename or die "Cannot open file: $filename: $!";
    print {$ofh} $content;
    close $ofh;
}

sub load_asset {
    my ($self, $asset) = @_;
    return if $self->{_asset_seen}->{$asset}++;

    my $klass = Plack::Util::load_class($asset, 'Amon2::Setup::Asset');

    my $require_newline = $self->{tags} ? 1 : 0;
    $self->{tags} .= $klass->tags;
    $self->{tags} .= "\n" if $require_newline;

    push @{$self->{assets}}, $klass;
}

1;
__END__

=head1 NAME

Amon2::Setup - setup amon2 project

=head1 SYNOPSIS

    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run('Basic');
    # or
    $setup->run('Teng', 'Dotcloud', 'Basic');

