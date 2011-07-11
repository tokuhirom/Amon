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

