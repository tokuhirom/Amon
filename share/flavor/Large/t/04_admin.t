use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $admin = Plack::Util::load_psgi '<% $psgi_file %>';
test_psgi
    app => $admin,
    client => sub {
        my $cb = shift;

        # 401
        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            my $res = $cb->($req);
            is($res->code, 401, 'basic auth');
        }

        # 200
        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            $req->authorization_basic('admin', 'admin');
            my $res = $cb->($req);
            is($res->code, 200, 'basic auth');
            like($res->content, qr{admin});
        }
    };

done_testing;
