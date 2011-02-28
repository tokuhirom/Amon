use strict;
use warnings;
use utf8;
use Amon2::Web::Request;
use URI::Escape;
use Encode;
use Test::More;
use Amon2;

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
    sub encoding { 'utf-8' }
}

{
    package MyApp;
    use parent qw/Amon2/;
}

my $req = Amon2::Web::Request->new({
    QUERY_STRING   => 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2',
    REQUEST_METHOD => 'GET',
    SCRIPT_NAME => '/foo/',
});
my $c = MyApp::Web->new(request => $req);

my $uri = $c->uri_for('/bar/', {'boo' => 'ジョン'});
is $uri, '/foo/bar/?boo=%E3%82%B8%E3%83%A7%E3%83%B3';
is decode_utf8(+{URI->new($uri)->query_form}->{'boo'}), 'ジョン';

done_testing;
