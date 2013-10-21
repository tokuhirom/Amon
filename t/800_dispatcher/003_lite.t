use strict;
use warnings;
use Test::More tests => 4;
use Test::Requires 'Router::Simple', 'Router::Simple::Sinatraish';

{
    package MyApp;
    use parent qw/Amon2/;

    package MyApp::V::MT;

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::Lite '-base';

    get '/' => sub {
        my $c = shift;
        $c->create_response(200, [], 'ok')
    };
    get '/hello/:name' => sub {
        my ($c, $args) = @_;
        $c->create_response(200, [], ["hi, $args->{name}"])
    };
    post '/new' => sub {
        my ($c, $args) = @_;
        $c->create_response(200, [], ["post"])
    };
}

my $app = MyApp::Web->to_app();
{
    my $ret = $app->({
        PATH_INFO      => '/',
        REQUEST_METHOD => 'GET',
    });
    is $ret->[2]->[0], 'ok';
}
{
    my $ret = $app->({
        PATH_INFO      => '/hello/tokuhirom',
        REQUEST_METHOD => 'GET',
    });
    is $ret->[2]->[0], 'hi, tokuhirom';
}
{
    my $ret = $app->({
        PATH_INFO      => '/hello/tokuhirom',
        REQUEST_METHOD => 'POST',
    });
    is $ret->[0], 405, 'Method not allowed';
}
{
    my $ret = $app->({
        PATH_INFO      => '/new',
        REQUEST_METHOD => 'POST',
    });
    is $ret->[2]->[0], 'post';
}

