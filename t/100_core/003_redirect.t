use strict;
use warnings;
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
done_testing;

# -------------------------------------------------------------------------

sub check_redirect {
    my ($env, $next) = @_;
    $c->{request} = Amon2::Web::Request->new($env);

    my $res = $c->redirect($next);
    $res->header('Location');
}

