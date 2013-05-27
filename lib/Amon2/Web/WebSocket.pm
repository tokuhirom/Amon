package Amon2::Web::WebSocket;
use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
        %args
    }, $class;
}

sub on_receive_message {
    my ( $self, $code ) = @_;
    $self->{on_receive_message} = $code;
}

sub on_error {
    my ( $self, $code ) = @_;
    $self->{on_error} = $code;
}

sub on_eof {
    my ( $self, $code ) = @_;
    $self->{on_eof} = $code;
}

sub call_receive_message {
    my ( $self, $c, $message ) = @_;
    if ( $self->{on_receive_message} ) {
        $self->{on_receive_message}->( $c, $message );
    }
}

sub call_error {
    my ( $self, $c ) = @_;
    if ( $self->{on_error} ) {
        $self->{on_error}->($c);
    }
}

sub call_eof {
    my ( $self, $c ) = @_;
    if ( $self->{on_eof} ) {
        $self->{on_eof}->($c);
    }
}

sub send_message {
    my ( $self, $message ) = @_;
    $self->{send_message}->($message);
}

1;
__END__

=head1 NAME

Amon2::Web::WebSocket - WebSocket support for Amon2

=head1 DESCRIPTION

This module is a helper class for WebSocket support for Amon2.

see L<Amon2::Plugin::Web::WebSocket> for concrete usage.

=head1 METHODS

=over 4

=item C<< $ws->on_receive_message(\&code); >>

=item C<< $ws->on_eof(\&code); >>

=item C<< $ws->on_error(\&code); >>

set a callback function on received event.

=back
