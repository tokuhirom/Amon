use strict;
use warnings;
use Test::More;
use t::Util;

plan skip_all => "this test requires perl 5.10 or later" if $] < 5.010;

run_app_test('DeepNamespace');
