use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'JSON';
use Plack::Util;
use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::Util::load_psgi('t/400_lite/02_plugin.psgi');
is(ref $app, 'CODE');
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->content, '{"ok":1}';
};

done_testing;

