use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;

test_flavor(sub {
    ok(-f 'dotcloud.yml', 'dotcloud.yml exists');
}, 'DotCloud');

done_testing;

