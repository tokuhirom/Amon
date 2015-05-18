use strict;
use warnings;
use Test::More;
use Test::Requires 'JSON';
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
        'Web::JSON' => { canonical => 1 }
    );
}

my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{}));
{
    my $res = $c->render_json(+{ a=>1, b=>2, c=>3, d=>4, e=>5, f=>6, g=>7, h=>8, i=>9 });

    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|;
}

done_testing;

