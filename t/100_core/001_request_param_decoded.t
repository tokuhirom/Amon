use strict;
use warnings;
use utf8;
use Amon2::Web::Request;
use URI::Escape;
use Encode;
use Test::More;
use Amon2;

BEGIN {
    $INC{'MyApp.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
}

{
    package MyApp::Web;
    use Amon2::Web -base => (
        base_name => 'MyApp',
        dispatcher_class => 'Amon2::Web::Dispatcher',
        default_view_class => 'Text::MicroTemplate::File',
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp;
    use Amon2 -base;
}

my $c = MyApp::Web->bootstrap();

my $req = Amon2::Web::Request->new({
    QUERY_STRING   => 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2',
    REQUEST_METHOD => 'GET',
});
ok Encode::is_utf8($req->param_decoded('foo')), 'decoded';
is $req->param_decoded('foo'), 'ほげ';
is_deeply [$req->param_decoded('bar')], ['ふが1', 'ふが2'];

done_testing;
