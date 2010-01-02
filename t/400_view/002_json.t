use strict;
use warnings;
use lib 't/apps/Extended/lib/';
use Test::Requires 'JSON';
use Test::More;
use Extended::Web;
use Amon::Web::Request;

my $c = Extended::Web->bootstrap(
    request => Amon::Web::Request->new(+{
        REQUEST_METHOD => 'GET',
    })
);
is $c->view('JSON')->render({a => 'b'}), '{"a":"b"}';
is_deeply(
    $c->view('JSON')->make_response({a => 'b'}),
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
