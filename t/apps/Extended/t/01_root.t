use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'Extended.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/', [
            'User-Agent' => 'DoCoMo/1.0/P502i/c10',
        ]);
        my $res = $cb->($req);
        is $res->code, 200;
        like $res->content, qr/DoCoMo world!/;
    };

done_testing;
