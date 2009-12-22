use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use Plack::Util;
use Plack::Test;
use Cwd;
use Test::More;
use App::Prove;

chdir 't/apps/DeepNamespace/' or die $!;

my $app = App::Prove->new();
$app->process_args('-Ilib', <t/*.t>);
ok($app->run);
done_testing;
