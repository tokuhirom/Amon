use strict;
use warnings;
use Test::More;
use Amon2::Web::Response;

subtest 'at_a_time' => sub {
    my $res = Amon2::Web::Response->new(200, [], 'ok');
    $res->content_type('text/html');
    $res->status(403);
    $res->body('hoge');
    isa_ok $res, 'Amon2::Web::Response', 'method chain';
    is_deeply $res->finalize(), [403, ['Content-Type' => 'text/html'], ['hoge']];
};

subtest 'streaming' => sub {
    my $res = Amon2::Web::Response->new(200, []);
    $res->wait_for_events(sub {});
    isa_ok $res, 'Amon2::Web::Response';
		ok !$res->body;
    is ref($res->wait_for_events), 'CODE';
};

done_testing;
