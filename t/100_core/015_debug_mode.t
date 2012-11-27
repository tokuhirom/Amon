use strict;
use warnings;
use utf8;
use Test::More;
use Amon2;

subtest 'enabled debug mode' => sub {
    local $ENV{AMON2_DEBUG} = 1;
    is(Amon2->debug_mode(), 1);
};

subtest 'disabled debug mode' => sub {
    local $ENV{AMON2_DEBUG} = 0;
    is(Amon2->debug_mode(), 0);
};

done_testing;

