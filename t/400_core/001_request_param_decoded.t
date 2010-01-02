use strict;
use warnings;
use utf8;
use Amon::Web::Request;
use URI::Escape;
use Encode;
use Test::More;
use Amon;

{
    package MyApp::Web;
    use Amon::Web -base => (
        base_class => 'Amon',
        dispatcher_class => 'Amon::Web::Dispatcher',
        default_view_class => 'MT',
    );
    sub encoding { 'utf-8' }
}

my $c = MyApp::Web->bootstrap();

my $req = Amon::Web::Request->new({
    QUERY_STRING   => 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2',
    REQUEST_METHOD => 'GET',
});
ok Encode::is_utf8($req->param_decoded('foo')), 'decoded'; is
$req->param_decoded('foo'), 'ほげ'; is_deeply
[$req->param_decoded('bar')], ['ふが1', 'ふが2'];

done_testing;
