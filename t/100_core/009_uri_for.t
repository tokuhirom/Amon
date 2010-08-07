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
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
}

{
    package MyApp::Web;
    use Amon2::Web -base => (
        base_name => 'MyApp',
        view_class => 'Text::MicroTemplate::File',
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp;
    use Amon2 -base;
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
