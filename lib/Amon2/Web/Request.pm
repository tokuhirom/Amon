package Amon2::Web::Request;
use strict;
use warnings;
use base qw/Plack::Request/;
use Encode ();
use Carp ();
use URI::QueryParam;

sub body_parameters {
    my ($self) = @_;
    $self->{'amon2.body_parameters'} ||= $self->_decode_parameters($self->SUPER::body_parameters());
}

sub query_parameters {
    my ($self) = @_;
    $self->{'amon2.query_parameters'} ||= $self->_decode_parameters($self->SUPER::query_parameters());
}

sub _decode_parameters {
    my ($self, $stuff) = @_;

    my $encoding = Amon2->context->encoding;
    my @flatten = $stuff->flatten();
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode($encoding, $k), Encode::decode($encoding, $v);
    }
    return Hash::MultiValue->new(@decoded);
}

# code taken from Catalyst::Request
sub uri_with {
    my( $self, $args, $behavior) = @_;

    Carp::carp( 'No arguments passed to uri_with()' ) unless $args;

    my $append = 0;
    if((ref($behavior) eq 'HASH') && defined($behavior->{mode}) && ($behavior->{mode} eq 'append')) {
        $append = 1;
    }

    my $params = do {
        foreach my $value ( values %$args ) {
            next unless defined $value;
            for ( ref $value eq 'ARRAY' ? @$value : $value ) {
                $_ = "$_";
                utf8::encode($_) if utf8::is_utf8($_);
            }
        }

        my %params = %{ $self->uri->query_form_hash };
        foreach my $key ( keys %{$args} ) {
            my $val = $args->{$key};
            if ( defined($val) ) {

                if ( $append && exists( $params{$key} ) ) {

                  # This little bit of heaven handles appending a new value onto
                  # an existing one regardless if the existing value is an array
                  # or not, and regardless if the new value is an array or not
                    $params{$key} = [
                        ref( $params{$key} ) eq 'ARRAY'
                        ? @{ $params{$key} }
                        : $params{$key},
                        ref($val) eq 'ARRAY' ? @{$val} : $val
                    ];

                }
                else {
                    $params{$key} = $val;
                }
            }
            else {

                # If the param wasn't defined then we delete it.
                delete( $params{$key} );
            }
        }
        \%params;
    };

    my $uri = $self->uri->clone;
    $uri->query_form($params);

    return $uri;
}

1;
__END__

=head1 NAME

Amon2::Web::Request - Amon2 Request Class

=head1 DESCRIPTION

This is a child class of L<Plack::Request>. Please see L<Plack::Request> for more details.

=head1 AUTOMATIC DECODING

This class decode the query/body parameters automatically.

=head1 METHODS

=over 4

=item $req->uri_with($args, $behavior)

Returns a rewritten URI object for the current request. Key/value pairs passed in will override existing parameters. You can remove an existing parameter by passing in an undef value. Unmodified pairs will be preserved.

You may also pass an optional second parameter that puts uri_with into append mode:

  $req->uri_with( { key => 'value' }, { mode => 'append' } );

=back

=cut

