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

    $self->load_plugins(@{$plugins || []});
    $self->load_flavors(@$flavors);
    $self->run_flavors();
}

sub load_plugins {
    my ($self, @plugins) = @_;
    for my $plugin (@plugins) {
        $self->load_plugin($plugin);
    }
}

sub create_xslate {
    my ($self, @args) = @_;
    my $xslate = Text::Xslate->new(
        syntax => 'Kolon', # for template cascading
        type   => 'text',
        cache => 0,
        module => [
            'HTTP::Status' => ['status_message']
        ],
        @args,
    );
    return $xslate;
}

sub load_plugin {
    my ($self, $plugin) = @_;
    my $klass = Plack::Util::load_class($plugin, 'Amon2::Plugin');
    my $templates = $self->_load_templates($klass);
    my $xslate = $self->create_xslate();
    for my $key (sort keys %$templates) {
        my $t = $self->{plugin}->{$key};
        $t .= "\n" if defined $t && $t !~ /\n$/;
        $t .= $xslate->render_string($templates->{$key}, {%$self});
        $self->{plugin}->{$key} = $t;
    }
}

sub run_flavors {
    my ($self) = @_;

    my @path = @{$self->{flavors}};
    infof("Using flavors " . join(", ", map { $_->[0] } @path));
    my %flavor_seen;
    my %tmpl_seen;
    while (my $p = shift @path) {
        next if $flavor_seen{$p->[0]};

        local $_CURRENT_FLAVOR_NAME = $p->[0];
        for my $fname (sort { $a cmp $b } keys %{$p->[1]}) {
            next if $tmpl_seen{$fname}++;
            next if $fname =~ /^#/;
            $self->write_file($fname, $p->[1]->{$fname}, [$p, @path]);
        }
    }
}

sub write_file {
    my ($self, $fname_tmpl, $template, $thing) = @_;

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
    my ($self, @flavors) = @_;

    my @path;
    for my $flavor (@flavors) {
        push @path, $self->_load_flavor($flavor);
    }
    unless (grep { $_->can('is_standalone') && $_->is_standalone } map { $_->[0] } @path) {
        push @path, $self->_load_flavor('Basic');
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
    my ($self, $flavor) = @_;

    local $_CURRENT_FLAVOR_NAME = $flavor;
    infof("Loading $flavor");
    my $klass = Plack::Util::load_class($flavor, 'Amon2::Setup::Flavor');
    if ($klass->can('assets')) {
        for my $asset ($klass->assets()) {
            $self->load_asset($asset);
        }
    }
    my $all = $self->_load_templates($klass);

    my @ret;
    if ($klass->can('parent')) {
        for my $parent ($klass->parent()) {
            push @ret, $self->_load_flavor($parent);
        }
    }
    if ($klass->can('plugins')) {
        $self->load_plugins($klass->plugins);
    }
    return ([$klass, $all], @ret);
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

    $klass->run($self);
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

