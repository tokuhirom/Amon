package Amon::Web::Request;
use strict;
use warnings;
use base qw/Plack::Request/;
use Encode ();

sub param_decoded {
    my ($self, $param) = @_;
    return wantarray ? () : undef unless exists $self->parameters->{$param};
    my $encoding = Amon->context->encoding;
    my @values = $self->parameters->get_all($param);
    return wantarray()
        ? (map { Encode::decode($encoding, $_) } @values)
        : Encode::decode($encoding, $values[0]);
}

1;
__END__

=head1 NAME

Amon::Web::Request - Amon Request Class

=head1 DESCRIPTION

This is a child class of L<Plack::Request>.Please see L<Plack::Request> for more details.

=cut

