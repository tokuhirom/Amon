use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;
use Plack::Middleware::StackTrace;

my $app = Plack::Util::load_psgi 'Extended.psgi';
test_psgi
    app => Plack::Middleware::StackTrace->wrap($app),
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/die');
        my $res = $cb->($req);
        is $res->code, 500;
        like $res->content, qr/OKAY/;
        return;
    };

done_testing;
