use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common qw(GET POST);
use Test::More;

my $app = Plack::Util::load_psgi '<% $psgi_file // "app.psgi" %>';

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my %cookies;

        my $request = sub {
            my ($req) = @_;
            if (%cookies) {
                my $cookie = join '; ', map { "$_=$cookies{$_}" } sort keys %cookies;
                $req->header('Cookie' => $cookie);
            }

            my $res = $cb->($req);
            for my $set_cookie ($res->headers->header('Set-Cookie')) {
                my ($pair) = split /;/, $set_cookie, 2;
                my ($name, $value) = split /=/, $pair, 2;
                next unless defined $name && defined $value;
                $cookies{$name} = $value;
            }
            return $res;
        };

        my $get_res = $request->(GET 'http://localhost/__csrf_probe__');
        is $get_res->code, 404, 'GET probe path returns 404';
        ok $cookies{'XSRF-TOKEN'}, 'XSRF-TOKEN cookie is issued';

        my $post_no_token = $request->(POST 'http://localhost/reset_counter');
        is $post_no_token->code, 403, 'POST without token is rejected';

        my $post_bad_token = $request->(
            POST 'http://localhost/reset_counter',
            [ 'XSRF-TOKEN' => 'invalid-token' ]
        );
        is $post_bad_token->code, 403, 'POST with invalid token is rejected';

        my $post_ok = $request->(
            POST 'http://localhost/reset_counter',
            [ 'XSRF-TOKEN' => $cookies{'XSRF-TOKEN'} ]
        );
        is $post_ok->code, 302, 'POST with valid token is accepted';
    };

done_testing;
