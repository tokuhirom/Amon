use strict;
use warnings;
use Test::More;
use Amon::Web::Response;

my $res = Amon::Web::Response->new(200, [], 'ok');
isa_ok $res->content_type('text/html'), 'Amon::Web::Response', 'method chain';

done_testing;
