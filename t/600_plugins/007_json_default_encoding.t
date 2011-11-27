use strict;
use warnings;
use Test::More;
use Test::Requires 'JSON';

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
}

my $ua_opera  = 'Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686; ja) Opera 10.10';
my $ua_safari = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16';
my $ua_chrome = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.215 Safari/534.10';
{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{}));
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, '{"foo":"bar"}';
}
{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{
        HTTP_USER_AGENT => $ua_opera
    }));
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, '{"foo":"bar"}';
}
{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{
        HTTP_USER_AGENT => $ua_safari
    }));
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, "\xEF\xBB\xBF" . '{"foo":"bar"}';
}
{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{
        HTTP_USER_AGENT => $ua_chrome
    }));
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, "\xEF\xBB\xBF" . '{"foo":"bar"}';
}
{
    my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{
        HTTP_USER_AGENT => $ua_chrome,
        HTTP_X_REQUESTED_WITH => 'XMLHttpRequest'
    }));
    my $res = $c->render_json(+{"foo"=>"bar"});
    is $res->status, 200;
    is $res->header('Content-Type'), 'application/json; charset=utf-8';
    is $res->content, "\xEF\xBB\xBF" . '{"foo":"bar"}';
}
done_testing;

