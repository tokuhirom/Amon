package Amon2::Plugin::Web::WebSocket;
use strict;
use warnings;
use utf8;

use Amon2::Util;

use AnyEvent::Handle;
use Amon2::Web::WebSocket;
use Amon2::Web::Response::Callback;
use Protocol::WebSocket 0.00906;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::Handshake::Server;

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method(ref $c || $c, 'websocket', \&_websocket);
}

sub _websocket {
    my ($c, $code) = @_;

    my $fh = $c->req->env->{'psgix.io'}
        or return $c->create_response( 500, [], [] );
    my $ws = Amon2::Web::WebSocket->new();
    my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi(
        $c->req->env );
    $hs->parse($fh)
        or return $c->create_response( 400, [], [ $hs->error ] );
    my @messages;
    $ws->{send_message} = sub {
        my $message = shift;
        push @messages, $message;
    };
    $code->( $ws );
    my $res = Amon2::Web::Response::Callback->new(
        code => sub {
            my $respond = shift;
            eval {
                my $h = AnyEvent::Handle->new( fh => $fh );
                $ws->{send_message} = sub {
                    my $message = shift;
                    $message = Protocol::WebSocket::Frame->new($message)
                        ->to_bytes;
                    $h->push_write($message);
                };
                my $frame = Protocol::WebSocket::Frame->new();
                $h->push_write( $hs->to_string );
                $ws->send_message($_) for @messages;
                $h->on_read(
                    sub {
                        $frame->append( $_[0]->rbuf );
                        while ( my $message = $frame->next ) {
                            $ws->call_receive_message( $c, $message );
                        }
                    }
                );
                $h->on_error(
                    sub {
                        $ws->call_error($c);
                    }
                );
                $h->on_eof(
                    sub {
                        $ws->call_eof($c);
                        close $fh;
                    }
                );
            };
            if ($@) {
                warn $@;
                die "Cannot process websocket";
            }
        },
    );
    return $res;
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::WebSocket - [EXPERIMENTAL]WebSocket plugin for Amon2

=head1 SYNOPSIS

    use Amon2::Lite;

    any '/echo' => sub {
        my ($c) = @_;
        return $c->websocket(sub {
            my $ws = shift;
            $ws->on_receive_message(sub {
                my ($c, $message) = @_;
                $ws->send_message("YAY: " . $message);
            });
        });
    };

=head1 DESCRIPTION

This plugin provides WebSocket feature for Amon2.

You can use WebSocket very easily with Amon2.

This plugin depended on AnyEvent. You can use this module on L<Twiggy> only.

=head1 METHODS

=over 4

=item C<< $c->websocket(\&callback); >>

=back

=head1 SEE ALSO

L<Twiggy>, L<AnyEvent>

