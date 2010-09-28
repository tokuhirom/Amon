use strict;
use warnings;
use Test::More;
use Test::Requires 'Path::AttrRouter', 'Test::WWW::Mechanize::PSGI';

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
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
}

{
    package MyApp::Web::C;
    use base qw/Path::AttrRouter::Controller/;
    sub index :Path {
        my ($self, $c) = @_;
        $c->create_response(200, [], 'index');
    }

    sub index2 :Path :Args(2) {
        my ($self, $c, $x, $y) = @_;
        $c->create_response(200, [], "index2: $x, $y");
    }

    package MyApp::Web::C::Regex;
    use base qw/Path::AttrRouter::Controller/;

    sub index :Regex('^regex/(\d+)/(.+)') {
        my ($self, $c, $y, $m) = @_;
        $c->create_response(200, [], "regexp: $y, $m");
    }
}

{
    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::PathAttrRouter (
        search_path => 'MyApp::Web::C',
    );
}

my $app = MyApp::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('index');
$mech->get_ok('/a/b');
$mech->content_is("index2: a, b");
$mech->get_ok('/regex/1234/foo');
$mech->content_is( "regexp: 1234, foo");

done_testing;

