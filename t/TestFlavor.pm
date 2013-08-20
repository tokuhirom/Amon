use strict;
use warnings;
use utf8;

package t::TestFlavor;
use parent qw(Exporter);
our @EXPORT = qw(test_flavor);
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;
use Cwd;
use File::Spec;
use Plack::Util;
use Test::More;

sub test_flavor {
    my ($code, $flavor) = @_;

	local $ENV{PLACK_ENV} = 'development';
    $flavor = Plack::Util::load_class($flavor, 'Amon2::Setup::Flavor');

    my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', 'lib'));
    unshift @INC, $libpath;

    my $dir = tempdir(CLEANUP => $ENV{DEBUG} ? 0 : 1);
    my $cwd = Cwd::getcwd();
    chdir($dir);
    unshift @INC, "$dir/lib";
    note $dir;

    {
        $flavor->new(module => 'My::App')->run;
        $code->($flavor);

        # run prove
        my $app = App::Prove->new();
        $app->process_args('--norc', '--exec', "$^X -Ilib -Mlib=$libpath", <t/*.t>);
        ok($app->run);
    }

    note $dir;

    chdir($cwd);
}

1;

