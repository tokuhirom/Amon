use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;
use Cwd;
use Amon2::Setup::Flavor::DotCloud;

my $dir = tempdir(CLEANUP => 1);
my $cwd = Cwd::getcwd();
chdir($dir);

Amon2::Setup::Flavor::DotCloud->new(module => 'My::App')->run();

ok(-f 'dotcloud.yml', 'dotcloud.yml exists');

my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', '..', 'lib'));
my $app = App::Prove->new();
$app->process_args('-Ilib', "-I$libpath", <t/*.t>);
ok($app->run);
chdir($cwd);

done_testing;

