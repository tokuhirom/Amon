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

our $CURRENT_FLAVOR = 'main';

sub infof {
    print "[$CURRENT_FLAVOR] ";
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
    $self->{xslate} = Text::Xslate->new(
        syntax => 'Kolon', # for template cascading
        type   => 'text',
        tag_start => '<%',
        tag_end   => '%>',
    );
    return $self;
}

sub run_flavors {
    my ($self, @flavors)= @_;

    for my $flavor (@flavors) {
        $self->_run_flavor($flavor);
    }
}

sub _run_flavor {
    my ($self, $flavor) = @_;

    local $CURRENT_FLAVOR = $flavor;
    infof("Running $flavor");
    my $klass = Plack::Util::load_class($flavor, 'Amon2::Setup::Flavor');
    if ($klass->can('parent')) {
        for my $parent ($klass->parent()) {
            $self->_run_flavor($parent);
        }
    }
    if ($klass->can('prepare')) {
        $klass->prepare($self);
    }
    infof("$klass");
    my $reader = Data::Section::Simple->new($klass);
    my $all = $reader->get_data_section();
    unless ($all) {
        infof("There is no template");
    }
    while (my ($fname, $tmpl) = each %$all) {
        $self->write_file($fname, $tmpl);
    }
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

1;

