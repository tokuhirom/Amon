use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor;
use Text::Xslate;
use File::Spec;
use File::Basename;
use File::Path ();
use Amon2;
use Plack::Util ();
use Carp ();
use Amon2::Trigger;

my $xslate = Text::Xslate->new(
    syntax => 'TTerse',
    type   => 'text',
    tag_start => '<%',
    tag_end   => '%>',
    'module'   => [ 'Text::Xslate::Bridge::Star' ],
);

sub infof {
    my $caller = do {
        my $x;
        for (1..10) {
            $x = caller($_);
            last if $x ne __PACKAGE__;
        }
        $x;
    };
    $caller =~ s/^Amon2::Setup:://;
    print "[$caller] ";
    @_==1 ? print(@_) : printf(@_);
    print "\n";
}

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

sub run { die "This is abstract base method" }

sub mkpath {
    my ($self, $path) = @_;
    Carp::croak("path should not be ref") if ref $path;
    infof("mkpath: $path");
    File::Path::mkpath($path);
}

sub render_string {
    my $self = shift;
    my $template = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    return $xslate->render_string($template, {%$self, %args});
}

sub write_file {
    my ($self, $filename, $template) = (shift, shift, shift);
    Carp::croak("filename should not be reference") if ref $filename;

    $filename =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;

    my $content = $self->render_string($template, @_);
    $self->write_file_raw($filename, $content);
}

sub write_file_raw {
    my ($self, $filename, $content) = @_;
    Carp::croak("filename should not be reference") if ref $filename;

    infof("writing $filename");

    my $dirname = dirname($filename);
    File::Path::mkpath($dirname) if $dirname;

    open my $ofh, '>:encoding(utf-8)', $filename or die "Cannot open file: $filename: $!";
    print {$ofh} $content;
    close $ofh;
}

sub load_asset {
    my ($self, $asset) = @_;
    infof("Loading asset: $asset");
    my $klass = Plack::Util::load_class($asset, 'Amon2::Setup::Asset');

    my $require_newline = $self->{tags} ? 1 : 0;
    $self->{tags} .= $klass->tags;
    $self->{tags} .= "\n" if $require_newline;

    # $klass->run($self);
}

sub write_asset {
    my ($self, $asset, $base) = @_;
    $asset || die "Missing asset name";
    $base ||= 'static/';

    my $klass = Plack::Util::load_class($asset, 'Amon2::Setup::Asset');
    my $files = $klass->files;
    while (my ($fname, $content) = each %$files) {
        $self->write_file_raw("$base/$fname", $content);
    }
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor - Abstract base class for flavors.

=head1 DESCRIPTION

This is an abstract base class for flavors. But you don't need to inherit this class. Amon2 uses duck typing. You should implement only C<< Class->run >> method.

In Amon2, flavor means setup script.

=head1 METHODS

This class provides some useful methods to write setup script.

=over 4

=item $flavor->init()

Hook point to initialize module directory.

=item $flavor->mkpath($dir)

same as C<< `mkdir -p $dir` >>.

=item $flavor->write_file($fnametmpl, $template)

C<< $fnametmpl >> will be replace with the parameters.

Generate file using L<Text::Xslate>.

For more details, read the source Luke! Or please write docs...

=item $flavor->write_file_raw($fname, $content)

Write C<< $content >> to the C<< $fname >>.

=back

