use strict;
use warnings;
require Amon::Web::Declare;
use Amon::Web::Request;
use Test::More;

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'}           = __FILE__;
    $INC{'MyApp.pm'}                = __FILE__;
};

{
    package MyApp;
    use Amon -base;
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
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
    $c->{request} = Amon::Web::Request->new($env);

    my $res = Amon::Web::Declare::redirect($next);
    $res->header('Location');
}

