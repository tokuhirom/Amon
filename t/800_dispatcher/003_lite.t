use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    $INC{'MyApp.pm'}++;
    $INC{'MyApp/V/MT.pm'}++;
    $INC{'MyApp/Web/Dispatcher.pm'}++;
}

{
    package MyApp;
    use Amon2 -base;

    package MyApp::V::MT;

    package MyApp::Web;
    use Amon2::Web -base => (
        default_view_class => 'Text::MicroTemplate::File',
    );

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::Lite '-base';

    get '/' => sub {
        res(200, [], ['ok'])
    };
    get '/hello/:name' => sub {
        my ($c, $args) = @_;
        res(200, [], ["hi, $args->{name}"])
    };
    post '/new' => sub {
        my ($c, $args) = @_;
        res(200, [], ["post"])
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
        PATH_INFO      => '/new',
        REQUEST_METHOD => 'POST',
    });
    is $ret->[2]->[0], 'post';
}

