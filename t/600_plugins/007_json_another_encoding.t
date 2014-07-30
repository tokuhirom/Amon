use strict;
use warnings;
use utf8;
use Test::More;

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Encode;

    BEGIN {
        my $encoding = Encode::find_encoding('euc-jp') || die;
        sub encoding { $encoding }
    }

    __PACKAGE__->load_plugins(
        'Web::JSON',
    );
}

{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{}));
    my $res = $c->render_json(+{"寿"=>"司"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=euc-jp';
    is $res->content, '{"\u00bc\u00f7":"\u00bb\u00ca"}';
}
done_testing;

