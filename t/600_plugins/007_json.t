use strict;
use warnings;
use Test::More;
use JSON 2;

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;

    __PACKAGE__->load_plugins(
        'Web::JSON',
    );
    sub encoding { 'utf-8' }
}

my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{}));
# normal
{
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, '{"foo":"bar"}';
}

# xss
{
    my $src = { "foo" => "<script>alert(document.location)</script>" };
    my $res = $c->render_json($src);
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, '{"foo":"\u003cscript\u003ealert(document.location)\u003c/script\u003e"}';
    is_deeply decode_json($res->content), $src;
}
done_testing;

