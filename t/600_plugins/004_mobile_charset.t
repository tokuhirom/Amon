use strict;
use warnings;
use Test::More;
use Test::Requires 'HTTP::MobileAgent';

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use Amon -base;
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
    __PACKAGE__->load_plugins(
        'MobileAgent'   => {},
        'MobileCharset' => {},
    );
}

my $env = {
    HTTP_USER_AGENT => 'DoCoMo/1.0/P502i/c10',
};
my $c = MyApp::Web->bootstrap();
my $req = $c->request_class->new($env);
$c->{request} = $req;
is $c->encoding, 'x-sjis-docomo';
done_testing;

