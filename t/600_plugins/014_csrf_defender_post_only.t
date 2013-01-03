use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use Test::Requires 'Test::WWW::Mechanize::PSGI',
  'HTTP::Session::Store::OnMemory', 'Plack::Session', 'Data::Section::Simple',
  'Amon2::Lite';
use Plack::Builder;

our $COMMIT;

my $app = do {

    package MyApp::Web;
    use Amon2::Lite;

    sub load_config { +{} }

    my $session = HTTP::Session::Store::OnMemory->new();
    __PACKAGE__->load_plugins(
        'Web::HTTPSession' => {
            state => 'Cookie',
            store => sub { $session },
        },
        'Web::CSRFDefender',
        { post_only => 1 }
    );

    get '/form' => sub {
        my $c = shift;
        $c->render('form.tt');
    };
    get '/form_get' => sub {
        my $c = shift;
        $c->render('form_get.tt');
    };
    get '/form_no_method' => sub {
        my $c = shift;
        $c->render('form_no_method.tt');
    };
    get '/form_multi' => sub {
        my $c = shift;
        $c->render('form_multi.tt');
    };
    get '/do' => sub {
        my $c = shift;
        $COMMIT++;
        $c->redirect('/finished');
    };
    post '/do' => sub {
        my $c = shift;
        $COMMIT++;
        $c->redirect('/finished');
    };
    get '/finished' => sub {
        Plack::Response->new( 200, [], ['Finished'] );
    };

    __PACKAGE__->to_app;
};

subtest 'post method' => sub {
    local $COMMIT = 0;
    my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
    $mech->get_ok('http://localhost/form');
    $mech->content_like(
        qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
    $mech->submit_form( form_number => 1, fields => { body => 'yay' } );
    is $mech->base, 'http://localhost/finished';
    is $COMMIT, 1;
};

subtest 'deny' => sub {
    local $COMMIT = 0;
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do'));
            is $res->code, '403';
            is $COMMIT, 0;
        };
};

subtest 'get method' => sub {
    local $COMMIT = 0;
    my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
    $mech->get_ok('http://localhost/form_get');
    $mech->content_unlike(
        qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
    $mech->submit_form( form_number => 1, fields => { body => 'yay' } );
    is $mech->base, 'http://localhost/finished';
    is $COMMIT, 1;
};

subtest 'no method' => sub {
    local $COMMIT = 0;
    my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
    $mech->get_ok('http://localhost/form_no_method');
    $mech->content_unlike(
        qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
    $mech->submit_form( form_number => 1, fields => { body => 'yay' } );
    is $mech->base, 'http://localhost/finished';
    is $COMMIT, 1;
};

subtest 'multi form' => sub {
    my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
    $mech->get_ok('http://localhost/form_multi');
    $mech->content_like(
        qr[<form action="/do" method="post" id="f1">\n<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]m);
    $mech->content_like(
        qr[<form action="/do" method='POST' id="f2">\n<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]m);
    $mech->content_like(
        qr[<form action="/do" method=POST id="f3">\n<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]m);

    $mech->content_unlike(
        qr[<form action="/do" id="f4">\n<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]m);
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

@@ form_get.tt
<!doctype html>
<html>
<form action="/do" method="get">
    <input type="text" name="body" />
    <input type="submit" name="get" />
</form>
</html>

@@ form_no_method.tt
<!doctype html>
<html>
<form action="/do">
    <input type="text" name="body" />
    <input type="submit" name="get" />
</form>
</html>

@@ form_multi.tt
<!doctype html>
<html>
<form action="/do" method="post" id="f1">
    <input type="text" name="body" />
    <input type="submit" name="post" />
</form>

<form action="/do" method='POST' id="f2">
    <input type="text" name="body" />
    <input type="submit" name="post" />
</form>

<form action="/do" method=POST id="f3">
    <input type="text" name="body" />
    <input type="submit" name="post" />
</form>

<form action="/do" id="f4">
    <input type="text" name="body" />
    <input type="submit" name="get" />
</form>
</html>
