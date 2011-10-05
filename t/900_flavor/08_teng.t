use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::Requires {'Amon2::DBI' => 0.06};
use Test::More;
use Amon2::Setup;
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;
use Cwd;
use t::Util qw(slurp);

use Test::Requires qw(Teng);

note $^X;
note $];

my $orig_dir = Cwd::getcwd();
my $dir = tempdir(CLEANUP => 1);
chdir($dir) or die;

my $setup = Amon2::Setup->new(module => 'My::App');
$setup->run(['Teng']);

ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
    diag $@;
    diag do {
        open my $fh, '<', 'lib/My/App.pm' or die;
        local $/; <$fh>;
    };
};
like(slurp('lib/My/App.pm'), qr{DBI});
is( scalar( my @files = glob('static/js/jquery-*.js') ), 1 );

{
    my $_00_compile = slurp("t/00_compile.t");
    like $_00_compile, qr(My::App);
    like $_00_compile, qr(My::App::Web);
    like $_00_compile, qr(My::App::Web::Dispatcher);
    like $_00_compile, qr(My::App::DB::Schema);
    like $_00_compile, qr(My::App::DB);
};

my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', '..', 'lib'));
system("$^X", '-Ilib', "-I$libpath", "script/make_schema.pl")==0
    or die "Cannot run schema dumper";
my $app = App::Prove->new();
$app->process_args('-Ilib', "-I$libpath", <t/*.t>);
ok($app->run);

chdir($orig_dir);
undef $dir;

done_testing;

