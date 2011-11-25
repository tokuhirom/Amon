use strict;
use warnings;
use utf8;
use Test::More;

my $app = do {
    package MyApp;
    use parent qw(Amon2::Web Amon2);
    __PACKAGE__->load_plugins(qw(Web::JSON));
    __PACKAGE__->new();
};
subtest 'without X-Requested-With header' => sub {
    $app->{request} = Amon2::Web::Request->new(
        +{
            'HTTP_USER_AGENT' => 'Mozilla/5.0 (Linux; U; Android 2.3.2; ja-jp; SonyEricssonSO-01C Build/3.0.D.2.79) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
            'HTTP_COOKIE' => 'nantoka_sid=foo',
        }
    );
    my $res = $app->render_json({});
    is($res->code, 403);
    is($res->content_length, length($res->content));
};
subtest 'POST request' => sub {
    $app->{request} = Amon2::Web::Request->new(
        +{
            'REQUEST_METHOD' => 'POST',
            'HTTP_USER_AGENT' => 'Mozilla/5.0 (Linux; U; Android 2.3.2; ja-jp; SonyEricssonSO-01C Build/3.0.D.2.79) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
            'HTTP_COOKIE' => 'nantoka_sid=foo',
        }
    );
    my $res = $app->render_json({});
    is($res->code, 200);
    is($res->content_length, length($res->content));
};

subtest 'with X-Requested-With header' => sub {
    $app->{request} = Amon2::Web::Request->new(
        +{
            'HTTP_USER_AGENT' => 'Mozilla/5.0 (Linux; U; Android 2.3.2; ja-jp; SonyEricssonSO-01C Build/3.0.D.2.79) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
            'HTTP_COOKIE' => 'nantoka_sid=foo',
            'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest',
        }
    );
    my $res = $app->render_json({});
    is($res->code, 200);
    is($res->content, "\xEF\xBB\xBF{}");
};

done_testing;

