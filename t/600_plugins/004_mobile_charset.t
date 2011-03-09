use strict;
use warnings;
use Test::More;
use Test::Requires 'HTTP::MobileAgent', 'HTTP::MobileAgent::Plugin::Charset', 'Encode::JP::Mobile', 'Tiffany';

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
    __PACKAGE__->load_plugins(
        'Web::MobileAgent'   => {},
        'Web::MobileCharset' => {},
    );
}

my $env = {
    HTTP_USER_AGENT => 'DoCoMo/1.0/P502i/c10',
};
my $c = MyApp::Web->bootstrap();
my $req = $c->create_request($env);
$c->{request} = $req;
is $c->encoding, 'x-sjis-docomo';
done_testing;

