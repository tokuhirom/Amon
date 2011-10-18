use strict;
use warnings;
use Test::More;
use Test::Requires 'HTTP::BrowserDetect';

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
    __PACKAGE__->load_plugins(
        'Web::BrowserDetect' => {},
    );
}

my $env = {
    HTTP_USER_AGENT => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; ja-jp) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7',
};
my $c = MyApp::Web->new();
my $req = $c->create_request($env);
$c->{request} = $req;
ok $c->browser_detect->iphone;
done_testing;
