use strict;
use warnings;
use Test::Requires 'JSON';
use Test::More;
use Amon::Web::Request;

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/JSON.pm'}         = __FILE__;
    $INC{'MyApp.pm'}                = __FILE__;
};

{
    package MyApp;
    use Amon -base;

    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'JSON',
    );

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher;

    package MyApp::V::JSON;
    use base qw/Amon::V::JSON/;
}

my $c = MyApp::Web->bootstrap(
    request => Amon::Web::Request->new(+{
        REQUEST_METHOD => 'GET',
    })
);
is $c->view('JSON')->render({a => 'b'}), '{"a":"b"}';
is_deeply(
    $c->view('JSON')->make_response({a => 'b'})->finalize(),
    [
        200,
        [
            'Content-Length' => 9,
            'Content-Type' => 'application/json; charset=utf-8'
        ],
        [
            '{"a":"b"}'
        ]
    ]
);
done_testing;
