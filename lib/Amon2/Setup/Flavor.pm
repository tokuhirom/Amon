use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor;
use Text::Xslate;
use File::Spec;
use File::Basename;
use File::Path ();
use Amon2;

my $xslate = Text::Xslate->new(
    syntax => 'Kolon',
    type   => 'text',
    tag_start => '<%',
    tag_end   => '%>',
);

sub infof { @_==1 ? print(@_) : printf(@_); print "\n" }

sub new {
    my $class = shift;
    my %args = @_ ==1 ? %{$_[0]} : @_;

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
    bless { %args }, $class;
}

sub init {
    my $self = shift;

    my $dist = $self->{dist};
    mkdir $dist or die "Cannot mkdir '$dist': $!";
    chdir $dist or die $!;
}

sub run { die "This is abstract base method" }

sub mkpath {
    my ($self, $path) = @_;
    infof("mkpath: $path");
    File::Path::mkpath($path);
}

sub write_file {
    my ($self, $filename, $template) = @_;

    $filename =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;

    my $content = $xslate->render_string($template, +{%$self});
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

1;

