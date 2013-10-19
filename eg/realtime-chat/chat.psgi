use strict;
use warnings;
use utf8;
use Amon2::Lite;
use Digest::MD5 ();

print "PID: $$\n";

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

my $clients = {};

any '/echo2' => sub {
    my ($c) = @_;
    my $id = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);

    $c->websocket(sub {
        my $ws = shift;
        $clients->{$id} = $ws;

        $ws->on_receive_message(sub {
            my ($c, $message) = @_;
            for (keys %$clients) {
                $clients->{$_}->send_message(
                    "MSG: $message"
                );
            }
        });
        $ws->on_eof(sub {
            my ($c) = @_;
            delete $clients->{$id};
        });
        $ws->on_error(sub {
            my ($c) = @_;
            delete $clients->{$id};
        });
    });
};

# load plugins
__PACKAGE__->load_plugin('Web::WebSocket');
__PACKAGE__->enable_middleware('AccessLog');
__PACKAGE__->enable_middleware('Lint');

__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>WS</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css">
</head>
<body data-host_port="[% c().req.uri.host_port %]">
    <div class="container">
        <header><h1>WS</h1></header>
        <div class="row">
            <form id="form">
                <input type="text" name="message" id="message">
                <input type="submit" class="btn">
            </form>
            <pre id="log"></pre>
        </div>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
    <script type="text/javascript">
        function log(msg) {
            $('#log').text($('#log').text() + msg + "\n");
        }

        $(function () {
            var hostport = $(document.body).data('host_port');
            var ws = new WebSocket('ws://' + hostport + '/echo2');
            ws.onopen = function () {
                log('connected');
            };
            ws.onclose = function (ev) {
                log('closed');
            };
            ws.onmessage = function (ev) {
                log('received: ' + ev.data);
                $('#message').val('');
            };
            ws.onerror = function (ev) {
                console.log(ev);
                log('error: ' + ev.data);
            };
            $('#form').submit(function () {
                ws.send($('#message').val());
                return false;
            });
        });
    </script>
</body>
</html>
