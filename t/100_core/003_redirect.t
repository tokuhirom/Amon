use strict;
use warnings;
use utf8;
use Amon2::Web::Request;
use Test::More;

{
    package MyApp::Web;
    use parent qw/Amon2 Amon2::Web/;
}

my $c = MyApp::Web->bootstrap();

# -------------------------------------------------------------------------

is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
        },
        '/foo/'
    ),
    'http://example.com/foo/'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        '/foo/'
    ),
    'http://example.com/bar/foo/'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/'
    ),
    'http://google.com/'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/',
        ['foo' => 'bar']
    ),
    'http://google.com/?foo=bar'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/?hoge=fuga',
        ['foo' => 'bar']
    ),
    'http://google.com/?hoge=fuga&foo=bar'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/?foo=hoge',
        ['foo' => 'bar']
    ),
    'http://google.com/?foo=hoge&foo=bar'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/?foo=hoge',
        ['いやん' => 'ばかん']
    ),
    'http://google.com/?foo=hoge&%E3%81%84%E3%82%84%E3%82%93=%E3%81%B0%E3%81%8B%E3%82%93'
);
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/?foo=hoge',
        {'いやん' => 'ばかん'}
    ),
    'http://google.com/?foo=hoge&%E3%81%84%E3%82%84%E3%82%93=%E3%81%B0%E3%81%8B%E3%82%93'
);

no warnings 'once';
local *MyApp::Web::encoding = sub { 'cp932' };
is(
    check_redirect(
        {
            HTTP_HOST   => 'example.com',
            REQUEST_URI => '/',
            SCRIPT_NAME => '/bar/',
        },
        'http://google.com/?foo=hoge',
        ['いやん' => 'ばかん']
    ),
    'http://google.com/?foo=hoge&%82%A2%82%E2%82%F1=%82%CE%82%A9%82%F1'
);
done_testing;

# -------------------------------------------------------------------------

sub check_redirect {
    my ($env, $next, $params) = @_;
    $c->{request} = Amon2::Web::Request->new($env);

    my $res = $c->redirect($next, $params);
    $res->header('Location');
}

