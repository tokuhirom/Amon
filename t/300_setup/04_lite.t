use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Setup::Flavor::Lite;
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/../../lib/";

my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', '..', 'lib'));

my $dir = tempdir(CLEANUP => 1);
my $cwd = Cwd::getcwd();
chdir($dir);

Amon2::Setup::Flavor::Lite->new(PATH => 'My/App', module => 'My::App')->run();

ok(-f 'app.psgi', 'app.psgi exists');
ok((do 'app.psgi'), 'app.psgi is valid') or do {
    diag $@;
    diag do {
        open my $fh, '<', 'app.psgi' or die;
        local $/; <$fh>;
    };
};

my $app = App::Prove->new();
$app->process_args('-Ilib', "-I$libpath", <t/*.t>);
ok($app->run);
chdir($cwd);

done_testing;

