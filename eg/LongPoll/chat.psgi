use strict;
use warnings;
use utf8;
use Amon2::Lite;
use Digest::MD5 ();
use Tatsumaki::MessageQueue;
use Amon2::Web::Response::Callback;

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

my $mq = Tatsumaki::MessageQueue->instance('chat');

any '/post' => sub {
    my $c = shift;
    $mq->publish(
        {
            type    => 'message',
            message => scalar($c->req->param('message')),
        }
    );
    return $c->render_json({ok => 1});
};

any '/poll' => sub {
    my ($c) = @_;

    my $client_id = $c->req->param('client_id')
        or die;
    return $c->streaming_json(sub {
        my $writer = shift;

        $mq->poll_once($client_id, sub {
            $writer->write_json(\@_);
            $writer->close;
        });
    });
};

# load plugins
__PACKAGE__->load_plugin('Web::JSON');
__PACKAGE__->load_plugin('Web::Streaming');
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
    <script type="text/javascript" src="https://raw.github.com/beppu/jquery-ev/master/jquery.ev.js"></script>
    <link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <header><h1>WS</h1></header>
        <section class="row">
            <form id="form">
                <input type="text" name="message" id="message">
                <input type="submit" class="btn">
            </form>
            <pre id="log"></pre>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
    <script type="text/javascript">
        function log(msg) {
            $('#log').text($('#log').text() + msg + "\n");
        }

        $(function () {
            var client_id = Math.random();
            $.ev.loop('/poll?client_id=' + client_id, {
                message: function (ev) {
                    log(ev.message);
                }
            });
            $('#form').submit(function () {
                var message = $('#message').val();
                $('#message').val('');
                $.ajax({
                    url: '/post',
                    data: {
                        message: message
                    }
                });
                return false;
            });
        });
    </script>
</body>
</html>
