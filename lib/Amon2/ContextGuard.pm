package Amon2::ContextGuard;
# THIS IS INTERNAL CLASS.
# DO NOT USE THIS CLASS DIRECTLY.
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $context, $dst) = @_;
    my $orig = $$dst;
    $$dst = $context;
    bless [$orig, $dst], $class;
}

sub DESTROY {
    my $self = shift;

    # paranoia: guard against cyclic reference
    delete ${$self->[1]}->{$_} for keys %{${$self->[1]}};

    ${$self->[1]} = $self->[0];
}

1;

