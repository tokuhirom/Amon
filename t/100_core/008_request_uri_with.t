use strict;
use warnings;
use Test::More;
use Encode;

{
    package MyApp;
    use parent qw(Amon2 Amon2::Web);
}

my $c = MyApp->bootstrap;

subtest 'normal' => sub {
    my $req = Amon2::Web::Request->new(
        {
            HTTP_HOST => 'localhost',
            PATH_INFO => '/foo/',
            QUERY_STRING => 'a=b&c=d',
        },
    );
    my $uri = $req->uri_with({e => 'f'});
    is_deeply +{$uri->query_form()}, {
        e => 'f',
        a => 'b',
        c => 'd',
    };
};

subtest 'flagged key' => sub {
    my $req = Amon2::Web::Request->new(
        {
            HTTP_HOST => 'localhost',
            PATH_INFO => '/foo/',
            QUERY_STRING => 'a=%E3%81%BB%E3%81%92&c=d',
        },
    );
    my $uri = $req->uri_with({
        decode_utf8('e') => 'f'
    });
    is_deeply +{$uri->query_form()}, {
        e => 'f',
        a => 'ほげ',
        c => 'd',
    };
};

done_testing;
