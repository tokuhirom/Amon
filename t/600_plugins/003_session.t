use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';
use Plack::Middleware::Lint;

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use Amon -base;

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher;
    sub dispatch {
        my ($class, $c) = @_;
        if ($c->request->path_info eq '/') {
            c->session->set(foo => 'bar');
            return redirect('/step2');
        } elsif ($c->request->path_info eq '/step2') {
            my $res = "<html><body>@{[  c->session->get('foo') ]}</body></html>";
            return res(
                200,
                [
                    'Conent-Length' => length($res),
                    'Content-Type'  => 'text/plain'
                ],
                $res
            );
        } else {
            return res_404();
        }
    }

    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
    __PACKAGE__->load_plugins(
        'HTTPSession' => {
            state => 'URI',
            store => 'OnMemory',
        },
    );
}

my $app = MyApp::Web->to_app(
    config => {
        'HTTP::Session::State::URI' => {
            session_id_name => 'amon_sid',
        },
    },
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

