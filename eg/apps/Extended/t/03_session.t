use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';
use Extended::Web;

my $app = Extended::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/session');
$mech->content_contains('first time');
$mech->get_ok('/session');
$mech->content_contains('hello, 1');
$mech->get_ok('/session');
$mech->content_contains('hello, 2');

done_testing;
