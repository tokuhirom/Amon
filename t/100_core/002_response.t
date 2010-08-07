use strict;
use warnings;
use Test::More;
use Amon2::Web::Response;

my $res = Amon2::Web::Response->new(200, [], 'ok');
isa_ok $res->content_type('text/html')->status(403)->body('hoge'), 'Amon2::Web::Response', 'method chain';
is_deeply $res->finalize(), [403, ['Content-Type' => 'text/html'], ['hoge']];

done_testing;
