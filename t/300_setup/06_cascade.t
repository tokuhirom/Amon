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

subtest 'F1' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run('+F1');
    is(slurp('X'), "YYY\n");
};

subtest 'F2' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run('+F2');
    is(slurp('X'), "YYY\nZZZ\n");
};

subtest 'F3' => sub {
    my $guard = t::Util::Chdir->new();
    my $setup = Amon2::Setup->new(module => 'My::App');
    $setup->run('+F3');
    is(slurp('X'), "XXX\nYYY\nZZZ\n");
};

done_testing;

