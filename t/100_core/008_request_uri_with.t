use strict;
use warnings;
use Amon::Web::Request;
use Test::More;

my $req = Amon::Web::Request->new(
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

done_testing;
