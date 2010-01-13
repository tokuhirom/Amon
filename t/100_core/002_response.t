use strict;
use warnings;
use Test::More;
use Amon::Web::Response;

my $res = Amon::Web::Response->new(200, [], 'ok');
isa_ok $res->content_type('text/html')->status(403)->body('hoge'), 'Amon::Web::Response', 'method chain';
is_deeply $res->finalize(), [403, ['Content-Type' => 'text/html'], ['hoge']];

done_testing;
