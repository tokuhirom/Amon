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

subtest 'F2' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run(['+F2']);
    is(slurp('X'), "YYY\nZZZ\n");
    ok(-f '1F');
    ok(-f '2F');
    is(slurp('inc'), "OK\n");
};

subtest 'F1' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run(['+F1']);
    is(slurp('X'), "YYY\n");
    ok(-f '1F');
    is(slurp('inc'), "OK\n");
};


subtest 'F3' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run(['+F3']);
    is(slurp('X'), "XXX\nYYY\nZZZ\n");
    ok(-f '1F');
    ok(-f '2F');
    ok(-f '3F');
};

done_testing;

