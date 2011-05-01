use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "This test doesn't runs without \$ENV{TEST_POD_COVERAGE}" unless $ENV{TEST_POD_COVERAGE};
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();
