use strict;
use warnings;
use Amon2::Web::Request;
use Test::More;

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Tiffany;
    sub create_view { Tiffany->load('Text::MicroTemplate::File') }
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
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

