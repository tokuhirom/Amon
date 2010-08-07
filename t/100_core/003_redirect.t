use strict;
use warnings;
use Amon2::Web::Request;
use Test::More;

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'}           = __FILE__;
    $INC{'MyApp.pm'}                = __FILE__;
};

{
    package MyApp;
    use Amon2 -base;
}

{
    package MyApp::Web;
    use Amon2::Web -base => (
        default_view_class => 'Text::MicroTemplate::File',
    );
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

