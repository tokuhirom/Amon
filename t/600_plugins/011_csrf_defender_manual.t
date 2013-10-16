use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'Plack::Session', 'Data::Section::Simple', 'Amon2::Lite', 'Amon2::Plugin::Web::CSRFDefender';
use Plack::Builder;

our $COMMIT;

{
    package MyApp::Web;
    use Amon2::Lite;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'Web::CSRFDefender', {no_validate_hook => 1}
    );

    get '/form' => sub {
        my $c = shift;
        $c->render('form.tt');
    };
    post '/do' => sub {
        my $c = shift;
        $COMMIT++;
        $c->redirect('/finished');
    };
    post '/do2' => sub {
        my $c = shift;
        if ($c->validate_csrf) {
            $c->create_response(200, [], ['valid token']);
        } else {
            $c->create_response(403, [], ['denied']);
        }
    };
    get '/finished' => sub {
        Plack::Response->new(200, [], ['Finished']);
    };
    get '/get_csrf_defender_token' => sub {
        my $c = shift;
        $c->create_response(200, [], [$c->get_csrf_defender_token()]);
    };
}

my $app = builder {
    enable 'Session';
    MyApp::Web->to_app();
};

subtest 'success case' => sub {
    local $COMMIT = 0;
    my $mech = Test::WWW::Mechanize::PSGI->new(
        app => $app,
    );
    $mech->get_ok('http://localhost/form');
    $mech->content_like(qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
    $mech->submit_form(form_number => 1, fields => {body => 'yay'});
    is $mech->base, 'http://localhost/finished';
    is $COMMIT, 1;
};

subtest 'there is no validation' => sub {
    local $COMMIT = 0;
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do'));
            is $res->code, '302';
            is $COMMIT, 1;
        };
};

subtest 'but you can validate manually' => sub {
    local $COMMIT = 0;
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do2'));
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

done_testing;

package MyApp::Web;
__DATA__

@@ form.tt
<!doctype html>
<html>
<form method="post" action="/do">
    <input type="text" name="body" />
    <input type="submit" name="post" />
</form>
</html>

