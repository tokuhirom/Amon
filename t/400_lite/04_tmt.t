use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use Test::Requires qw/Text::MicroTemplate Tiffany::Text::MicroTemplate::File/;
use HTTP::Request::Common;

use Amon2::Lite;

sub create_view {
    Tiffany::Text::MicroTemplate::File->new(+{
        include_path => ['./t/tmpl/']
    })
}

get '/' => sub {
    my ($c) = @_;
    return Amon2::Web::Response->new(200, [], 'OK');
};

get '/hello' => sub {
    my ($c) = @_;
    return $c->render('foo.mt', $c->req->param('name'));
};

my $app = __PACKAGE__->to_app;

test_psgi($app, sub {
    my $cb = shift;

    {
        my $res = $cb->(GET '/');
        is $res->content, 'OK';
    }

    {
        my $res = $cb->(GET '/hello?name=John');
        is $res->content, "Hello, John!\n";
    }
});

done_testing;

