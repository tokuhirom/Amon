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
use MRO::Compat;
use File::ShareDir ();
use Module::CPANfile 0.9020;

sub assets {
    my $self = shift;

    my @assets = qw(
        jQuery Bootstrap ES5Shim MicroTemplateJS StrftimeJS SprintfJS
        MicroLocationJS MicroDispatcherJS XSRFTokenJS
    );
    @assets;
}

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
    my $self = bless { %args }, $class;
    $self->{xslate} = $self->_build_xslate();
    $self->load_assets();
    $self;
}

sub _build_xslate {
    my $self = shift;

    my $xslate = Text::Xslate->new(
        syntax => 'Kolon',
        type   => 'text',
        tag_start => '<%',
        tag_end   => '%>',
        line_start => '%%',
        path => [ File::Spec->catdir(File::ShareDir::dist_dir('Amon2'), 'flavor') ],
        module => [
            'Amon2::Util' => ['random_string'],
        ],
    );
    $xslate;
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
    return $self->{xslate}->render_string($template, {%$self, %args});
}

sub render_file {
    my ($self, $dstname, $filename, $params) = @_;
    Carp::croak("filename should not be reference") if ref $filename;
    $dstname =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;

    my $content = $self->{xslate}->render($filename, {%$self, $params ? %$params : () });
    $self->write_file_raw($dstname, $content);
}

sub write_file {
    my ($self, $filename, $template) = (shift, shift, shift);
    Carp::croak("filename should not be reference") if ref $filename;

    $filename =~ s/<<([^>]+)>>/$self->{lc($1)} or die "$1 is not defined. But you want to use $1 in filename."/ge;

    my $content = $self->render_string($template, @_);
    $self->write_file_raw($filename, $content);
}

sub write_file_raw {
    my ($self, $filename, $content, $input_mode) = @_;
    Carp::croak("filename should not be reference") if ref $filename;
    $input_mode ||= '>:encoding(utf-8)';

    infof("writing $filename");

    my $dirname = dirname($filename);
    File::Path::mkpath($dirname) if $dirname;

    open my $ofh, $input_mode, $filename or die "Cannot open file: $filename: $!";
    print {$ofh} $content;
    close $ofh;
}

sub load_assets {
    my ($self) = @_;
    for my $asset ($self->assets) {
        $self->load_asset($asset);
    }
}

sub load_asset {
    my ($self, $asset) = @_;
    infof("Loading asset: $asset");
    my $klass = Plack::Util::load_class($asset, 'Amon2::Setup::Asset');

    my $require_newline = $self->{tags} ? 1 : 0;
    $self->{tags} .= $klass->tags;
    $self->{tags} .= "\n" if $require_newline && $self->{tags} !~ /\n\z/;

    # $klass->run($self);
}

sub write_asset {
    my ($self, $asset, $base) = @_;
    $asset || die "Missing asset name";
    $base ||= 'static/';

    my $klass = Plack::Util::load_class($asset, 'Amon2::Setup::Asset');
    my $files = $klass->files;
    while (my ($fname, $content) = each %$files) {
        my $layer = $fname =~ /\.js\z/ ? '>:encoding(utf-8)' : '>:raw';
        $self->write_file_raw("$base/$fname", $content, $layer);
    }
}

sub write_assets {
    my ($self, $dst) = @_;

    for my $asset ($self->assets) {
        $self->write_asset($asset, $dst);
    }
}

sub create_cpanfile {
    my ($self, $runtime_deps) = @_;
    $runtime_deps ||= +{};

    my $cpanfile = Module::CPANfile->from_prereqs(
        {
            runtime => {
                requires => {
                    'perl'              => '5.010_001',
                    'Amon2'             => $Amon2::VERSION,
                    'Text::Xslate'      => '2.0009',
                    'Starlet'           => '0.20',
                    'Module::Functions' => 2,
                    %$runtime_deps,
                },
            },
            configure => {
                requires => {
                    'Module::Build'    => '0.38',
                    'Module::CPANfile' => '0.9010',
                },
            },
            test => {
                requires => {
                    'Test::More' => '0.98',
                },
            },
        }
    );
    $self->write_file('cpanfile', $cpanfile->to_string());
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

=item C<< $flavor->init() >>

Hook point to initialize module directory.

=item C<< $flavor->mkpath($dir) >>

same as C<< `mkdir -p $dir` >>.

=item C<< $flavor->write_file($fnametmpl, $template) >>

C<< $fnametmpl >> will be replace with the parameters.

Generate file using L<Text::Xslate>.

For more details, read the source Luke! Or please write docs...

=item C<< $flavor->write_file_raw($fname, $content) >>

Write C<< $content >> to the C<< $fname >>.

=back

