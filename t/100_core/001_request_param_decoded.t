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
    sub encoding { 'utf-8' }
}

{
    package MyApp;
    use parent qw/Amon2/;
}

my $c = MyApp::Web->bootstrap();

my $req = Amon2::Web::Request->new({
    QUERY_STRING   => 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2',
    REQUEST_METHOD => 'GET',
});
subtest 'normal' => sub {
    ok Encode::is_utf8($req->param('foo')), 'decoded';
    ok Encode::is_utf8($req->query_parameters->{'foo'}), 'decoded';
    is $req->param('foo'), 'ほげ';
    is_deeply [$req->param('bar')], ['ふが1', 'ふが2'];
};
subtest 'accessor' => sub {
    ok !Encode::is_utf8($req->param_raw('foo')), 'not decoded';
    ok !Encode::is_utf8($req->parameters_raw->{'foo'}), 'not decoded';
};

done_testing;
