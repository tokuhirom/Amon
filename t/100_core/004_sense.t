use strict;
use warnings;
use Test::More;
use Amon::Sense;

can_ok(__PACKAGE__, qw(slurp try catch file dir catfile uri escape_html));

is escape_html(q{who's foo}), q{who&#39;s foo};

done_testing;
