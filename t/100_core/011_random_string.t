use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Util;

my $ret = Amon2::Util::random_string(32);
is length($ret), 32;

{
    my $ret = join '', map { Amon2::Util::random_string(32) } 1..100;
    like $ret, qr/A/;
    like $ret, qr/9/;
}

done_testing;

