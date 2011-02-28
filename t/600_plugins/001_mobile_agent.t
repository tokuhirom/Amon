use strict;
use warnings;
use Test::More;
use Test::Requires 'HTTP::MobileAgent';

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
        'Web::MobileAgent' => {},
    );
}

# TODO: refactor test with Test::MobileAgent
my $env = {
    HTTP_USER_AGENT => 'DoCoMo/1.0/P502i/c10',
};
my $c = MyApp::Web->new();
my $req = $c->create_request($env);
$c->{request} = $req;
is $c->mobile_agent->carrier, 'I';
done_testing;

