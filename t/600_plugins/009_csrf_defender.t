use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Session::Store::OnMemory', 'Plack::Session', 'Amon2::Plugin::Web::CSRFDefender', 'Amon2::Plugin::Web::HTTPSession';
use Plack::Builder;

my $COMMIT;

{
    package MyApp;
    use parent qw/Amon2/;

    sub load_config { +{} }

    package MyApp::Web::View;
    sub new {
        bless {}, shift;
    }
    sub render {
        '<!doctype html>
        <html>
        <form method="post" action="/do">
            <input type="text" name="body" />
            <input type="submit" name="post" />
        </form>
        </html>
        '
    }

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use HTTP::Session::Store::OnMemory;
    sub create_view { MyApp::Web::View->new() }
    sub dispatch {
        my $c = shift;
        ::like $c->get_csrf_defender_token(), qr{^[a-zA-Z0-9_]{32}$};
        if ($c->req->path_info eq '/form') {
            return $c->render('form.mt');
        } elsif ($c->req->path_info eq '/do' && $c->req->method eq 'POST') {
            $COMMIT++;
            return $c->redirect('/finished');
        } elsif ($c->req->path_info eq '/finished') {
            return $c->create_response(200, [], ['OK']);
        } elsif ($c->req->path_info eq '/get_csrf_defender_token') {
            return $c->create_response(200, [], [$c->get_csrf_defender_token]);
        } else {
            return $c->create_response(404, [], []);
        }
    }
    my $session = HTTP::Session::Store::OnMemory->new();
    __PACKAGE__->load_plugins(
        'Web::CSRFDefender' => {},
    );

    package MyApp::Web::HTTPSession;
    our @ISA = qw/MyApp::Web/;

    __PACKAGE__->load_plugins(
        'Web::HTTPSession' => {
            state => 'Cookie',
            store => sub { $session },
        },
    );

    package MyApp::Web::PlackSession;
    our @ISA = qw/MyApp::Web/;

    __PACKAGE__->load_plugins(
        'Web::PlackSession' => { },
    );
}

for my $klass (qw/MyApp::Web::HTTPSession MyApp::Web::PlackSession/) {
    my $app = builder {
        enable 'Session';
        $klass->to_app;
    };
    subtest $klass => sub {
        $COMMIT = 0;
        subtest 'success case' => sub {
            my $mech = Test::WWW::Mechanize::PSGI->new(
                app => $app,
            );
            $mech->get_ok('http://localhost/form');
            $mech->content_like(qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
            $mech->submit_form(form_number => 1, fields => {body => 'yay'});
            is $mech->base, 'http://localhost/finished';
            is $COMMIT, 1;
        };

        $COMMIT = 0;
        subtest 'deny' => sub {
            test_psgi
                app => $app,
                client => sub {
                    my $cb = shift;
                    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do'));
                    is $res->code, '403';
                    is $COMMIT, 0;
                };
        };

        subtest 'get_csrf_defender_token' => sub {
            test_psgi
                app => $app,
                client => sub {
                    my $cb = shift;
                    my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/get_csrf_defender_token'));
                    is $res->code, '200';
                    ::like $res->content(), qr{^[a-zA-Z0-9_]{32}$};
                };
        };
    };
}

done_testing;

