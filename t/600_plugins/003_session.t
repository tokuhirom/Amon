use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Session', 'HTML::StickyQuery', 'Amon2::Plugin::Web::MobileCharset';
use Plack::Middleware::Lint;
use Text::Xslate;

{
    package MyApp;
    use parent qw/Amon2/;
    sub load_config {
        +{ 'HTTP::Session::State::URI' => { session_id_name => 'amon_sid', }, };
    }

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;

    __PACKAGE__->load_plugin('Web::MobileCharset');
    __PACKAGE__->load_plugin('Web::MobileAgent');

    my $xslate = Text::Xslate->new(
        syntax => 'TTerse',
        function => {
            c => sub { Amon2->context },
        },
        path => {
            'step2' => <<'...',
<!doctype html>
<html><body>あいう[% c().session().get('foo') %]<form method="post" action="step3"><input type="submit" /></form></body></html>
...
            'step3' => <<'...',
<!doctype html>
<html><body>えおか[% c().session().get('foo') %]</body></html>
...
        },
    );
    sub create_view { $xslate }

    sub dispatch {
        my $c = shift;
        if ($c->request->path_info eq '/') {
            $c->session->set(foo => 'bar');
            return $c->redirect('/step2');
        } elsif ($c->request->path_info eq '/step2') {
            return $c->render('step2');
        } elsif ($c->request->path_info eq '/step3') {
            return $c->render('step3');
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

my $app = MyApp::Web->to_app;
   $app = Plack::Middleware::Lint->wrap($app);
my $mech = Test::WWW::Mechanize::PSGI->new(
    app                   => $app,
    max_redirect          => 0,
    requests_redirectable => []
);
$mech->get('/');
is $mech->status(), 302;
like $mech->res->header('Location'), qr[^http://localhost/step2\?amon_sid=(.{32})$];
$mech->res->header('Location') =~ qr[^http://localhost/step2\?amon_sid=(.{32})$];
my $sid = $1;
ok($sid);
$mech->get_ok($mech->res->header('Location'));
is(normalize($mech->content), normalize(<<"..."));
<!doctype html>
<html><body>あいうbar<form method="post" action="step3">
<input type="hidden" name="amon_sid" value="$sid" /><input type="submit" /></form></body></html>
...
$mech->submit_form_ok({form_number => 1});
is(normalize($mech->content), normalize(<<"..."));
<!doctype html>
<html><body>えおかbar</body></html>
...

done_testing;

sub normalize {
    local $_ = shift;
    s/\n$//;
    $_;
}
