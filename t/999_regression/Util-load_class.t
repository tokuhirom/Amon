use strict;
use warnings;
use Test::More;
use Amon::Util;

is Amon::Util::load_class('Data::Dumper'), 'Data::Dumper';
is Amon::Util::load_class('Data::Dumper'), 'Data::Dumper', 'function call of 2nd time returns same value';

done_testing;

