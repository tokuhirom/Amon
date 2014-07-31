use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Util;

diag sprintf("/dev/urandom: %s", $Amon2::Util::URANDOM_FH ? "available" : "unavailable");

my $ret = Amon2::Util::random_string(32);
is length($ret), 32;

{
    my $ret = join '', map { Amon2::Util::random_string(32) } 1..100;
    like $ret, qr/A/;
    like $ret, qr/9/;
}

for (1..100) {
    is length(Amon2::Util::random_string($_)), $_;
    {
        local $Amon2::Util::URANDOM_FH;
        is length(Amon2::Util::random_string($_)), $_;
    }
}

done_testing;

