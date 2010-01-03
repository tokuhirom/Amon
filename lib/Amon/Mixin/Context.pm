package Amon::Mixin::Context;
use strict;
use warnings;
use base qw/Exporter/;
our @EXPORT = qw/set_context context/;
use Scalar::Util ();

sub set_context {
    $_[0]->{context} = $_[1];
    Scalar::Util::weaken($_[0]->{context});
}
sub context     {
    $_[0]->{context};
}

1;
