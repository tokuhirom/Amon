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
use Plack::Util ();

our $CURRENT_FLAVOR_NAME;
our $CURRENT_FLAVOR_TMPL;
our $RENDERING_FILE;
our @PARENTS;

sub infof {
    my $flavor = $CURRENT_FLAVOR_NAME;
    $flavor =~ s!^Amon2::Setup::Flavor::!!;
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
    $self->{xslate} ||= Amon2::Setup::Xslate->new(
        syntax => 'Kolon', # for template cascading
        type   => 'text',
        tag_start => '<%',
        tag_end   => '%>',
        cache => 0,
        module => [
            'HTTP::Status' => ['status_message']
        ],
    );
    return $self;
}

# $setup->run_flavors('Teng', 'Basic')
sub run_flavors {
    my ($self, @flavors)= @_;

    my @path;
    for my $flavor (@flavors) {
        my ($klass, $tmpl) = $self->_load_flavor($flavor);
        my @p = ([$klass, $tmpl]);
        if ($klass->can('parent')) {
            for my $parent ($klass->parent()) {
                push @p, [$self->_load_flavor($parent)];
            }
        }
        push @path, @p;
    }

    my %flavor_seen;
    my %tmpl_seen;
    while (my $p = shift @path) {
        next if $flavor_seen{$p->[0]};
        local @PARENTS = @path;
        local $CURRENT_FLAVOR_NAME = $p->[0];
        local $CURRENT_FLAVOR_TMPL = $p->[1];
        for my $fname (sort keys %{$p->[1]}) {
            next if $tmpl_seen{$fname}++;
            next if $fname =~ /^#/;
            local $RENDERING_FILE = $fname;
            $self->write_file($fname, $p->[1]->{$fname});
        }
    }
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

    local $CURRENT_FLAVOR_NAME = $flavor;
    infof("Loading $flavor");
    my $klass = Plack::Util::load_class($flavor, 'Amon2::Setup::Flavor');
    if ($klass->can('prepare')) {
        infof("Preparing");
        $klass->prepare($self);
    }
    if ($klass->can('assets')) {
        for my $asset ($klass->assets()) {
            $self->load_asset($asset);
        }
    }
    my $all = $self->_load_templates($klass);
    return ($klass, $all);
}

sub write_file {
    my ($self, $filename, $template) = @_;

    $filename =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;

    my $content = $self->{xslate}->render_string($template, +{%$self});
    $self->write_file_raw($filename, $content);
}

sub write_file_raw {
    my ($self, $filename, $content) = @_;

    infof("writing $filename");

    my $dirname = dirname($filename);
    File::Path::mkpath($dirname) if $dirname;

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

sub mkpath {
    my ($self, $path) = @_;
    infof("mkpath: $path");
    File::Path::mkpath($path);
}

package # hide from pause
    Amon2::Setup::Xslate;

use parent qw(Text::Xslate);

# THIS IS *HACK*. I SHOULD BE REQUEST THE FEATURE TO THE ORIGINAL AUTHOR OF XSLATE.
sub find_file {
    my ($self, $file) = @_;

    my $tmpl = sub {
        my @path = @PARENTS;
        if ($file eq '!') {
            $file = $RENDERING_FILE;
        } elsif ($file =~ s/^!//) {
            # nop
        } else {
            unshift @path, [$CURRENT_FLAVOR_NAME, $CURRENT_FLAVOR_TMPL];
        }
        for my $parent (@path) {
            my $tmpl = $parent->[1]->{$file};
            return $tmpl if $tmpl;
        }
        die "Unknown template: $file";
    }->();
    my $cachepath = File::Spec->catfile(
        $self->{cache_dir},
        'CALLBACK',
        $file . 'c'
    );

    return {
        name        => $file,
        fullpath    => \$tmpl,
        cachepath   => $cachepath,
        orig_mtime  => 0,
        cache_mtime => 0,
    };
}

1;

