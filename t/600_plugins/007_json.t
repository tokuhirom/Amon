use strict;
use warnings;
use Test::More;

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
my $res = $c->render_json(+{"foo"=>"bar"});
is $res->status, 200;
is $res->header('Content-Type'), 'application/json; charset=utf-8';
is $res->content, '{"foo":"bar"}';
done_testing;

