use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'DeepNamespace.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
