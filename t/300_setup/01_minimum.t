use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Setup::Flavor::Minimum;
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;

my $dir = tempdir(CLEANUP => 1);
chdir($dir);

Amon2::Setup::Flavor::Minimum->new(PATH => 'My/App', module => 'My::App')->run();

ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
    diag $@;
    diag do {
        open my $fh, '<', 'lib/My/App.pm' or die;
        local $/; <$fh>;
    };
};

my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', '..', 'lib'));
my $app = App::Prove->new();
$app->process_args('-Ilib', "-I$libpath", <t/*.t>);
ok($app->run);

done_testing;

