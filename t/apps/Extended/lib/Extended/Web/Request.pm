package Extended::Web::Request;
use strict;
use warnings;
use base qw/Amon2::Web::Request/;
use HTTP::MobileAgent;

sub mobile_agent {
    my $self = shift;
    $self->{mobile_agent} ||= HTTP::MobileAgent->new($self->headers);
}

1;
