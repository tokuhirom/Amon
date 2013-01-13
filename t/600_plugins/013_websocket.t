use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Twiggy', 'Protocol::WebSocket::Handshake::Client';
use Test::Requires {
    'Protocol::WebSocket' => '0.00906',
};
use Test::TCP;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Protocol::WebSocket;
use Twiggy::Server;

use_ok 'Amon2::Plugin::Web::WebSocket';

use Amon2;
{
    package MyApp::Web;
    use parent qw/ Amon2 Amon2::Web /;
    use Test::More;
    __PACKAGE__->load_plugin('Amon2::Plugin::Web::WebSocket');

    sub dispatch {
        my $c = shift;

        $c->websocket( sub {
                my $ws = shift;

                $ws->on_receive_message( sub {
                        my ($c, $message) = @_;
                        ok $c;
                        isa_ok $c, 'Amon2::Web';
                        is $message, 'client-send';

                        $ws->call_eof($c);
                        $ws->call_error($c);
                        $ws->send_message('server-send');
                    },
                );
                $ws->on_eof(sub {
                        my ($c) = @_;
                        ok $c;
                        isa_ok $c, 'Amon2::Web';
                    },
                );
                $ws->on_error(sub {
                        my ($c) = @_;
                        ok $c;
                        isa_ok $c, 'Amon2::Web';

                        AE::cv->send;
                    },
                );
            },
        );
    }
}

my $client = sub {
    my ($host, $port) = @_;
    my $cv = AE::cv;
    my $handle; $handle = AnyEvent::Handle->new(
        connect => [$host, $port],
        on_connect => sub {
            my $hs = Protocol::WebSocket::Handshake::Client->new(url => "ws://$host:$port");
            $handle->push_write($hs->to_string);
        },
    );

    $handle->on_read( sub {
            my $h = shift;
            like $h->rbuf, qr/Upgrade/;

            my $frame = Protocol::WebSocket::Frame->new('client-send');
            $h->push_write($frame->to_bytes);

            delete $h->{rbuf};

            $h->on_read( sub {
                    my $frame = Protocol::WebSocket::Frame->new($_[0]->rbuf);
                    is $frame->next,'server-send';

                    $cv->send;
                    undef $handle;
                },
            );
        },
    );

    $cv->recv;
};

my $host = '127.0.0.1';
test_tcp(
    client => sub {
        my $port = shift;
        $client->($host, $port);
    },
    server => sub {
        my $port = shift;
        my $app    = MyApp::Web->to_app( );
        my $twiggy = Twiggy::Server->new(
            host => $host,
            port => $port,
        );
        $twiggy->register_service($app);

        AE::cv->recv;
    },
);

done_testing;
