use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;

use t::Util qw(slurp);
use Amon2::Setup;
use Cwd;
use lib Cwd::abs_path('lib/');
use lib Cwd::abs_path('t/300_setup/lib/');

subtest 'B1' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run(['+Plugin1', '+B1']);
    is(slurp('Makefile.PL'), "# B1\n# Plugin1-Makefile.PL\n");
    is(slurp('lib/My/App/Web.pm'), "# B1\n# Plugin1-lib/My/App/Web.pm\n\n");
    is(slurp('lib/My/App.pm'), "# B1\n# Plugin1-lib/My/App.pm\n\n");
};

done_testing;

