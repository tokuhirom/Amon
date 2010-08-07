use strict;
use warnings;
use Test::More;
use Amon2::Web::Response;

my $res = Amon2::Web::Response->new(200, [], 'ok');
$res->content_type('text/html');
$res->status(403);
$res->body('hoge');
isa_ok $res, 'Amon2::Web::Response', 'method chain';
is_deeply $res->finalize(), [403, ['Content-Type' => 'text/html'], ['hoge']];

done_testing;
