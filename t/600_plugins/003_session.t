use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Session', 'HTML::StickyQuery';
use Plack::Middleware::Lint;

{
    package MyApp;
    use parent qw/Amon2/;
    sub load_config {
        +{ 'HTTP::Session::State::URI' => { session_id_name => 'amon_sid', }, };
    }

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Tiffany;
    sub create_view { Tiffany->load('Text::MicroTemplate::File') }
    sub dispatch {
        my $c = shift;
        if ($c->request->path_info eq '/') {
            $c->session->set(foo => 'bar');
            return $c->redirect('/step2');
        } elsif ($c->request->path_info eq '/step2') {
            my $res = "<html><body>@{[  $c->session->get('foo') ]}</body></html>";
            return $c->create_response(
                200,
                [
                    'Conent-Length' => length($res),
                    'Content-Type'  => 'text/plain'
                ],
                $res
            );
        } else {
            return $c->create_response(404, [], []);
        }
    }

    __PACKAGE__->load_plugins(
        'Web::HTTPSession' => {
            state => 'URI',
            store => 'OnMemory',
        },
    );
}

my $app = MyApp::Web->to_app(
);
my $mech = Test::WWW::Mechanize::PSGI->new(
    app                   => $app,
    max_redirect          => 0,
    requests_redirectable => []
);
$mech->get('/');
is $mech->status(), 302;
like $mech->res->header('Location'), qr[^http://localhost/step2\?amon_sid=.{32}$];
$mech->get_ok($mech->res->header('Location'));
$mech->content_is('<html><body>bar</body></html>');

done_testing;

