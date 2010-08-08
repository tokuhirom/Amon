use strict;
use warnings;
use Test::More;
use Test::Requires 'HTTP::MobileAgent';

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent qw/MyApp Amon2::Web/;
    __PACKAGE__->setup(
        view_class => 'Text::MicroTemplate::File',
    );
    __PACKAGE__->load_plugins(
        'JSON',
    );
    sub encoding { 'utf-8' }
}

my $c = MyApp::Web->new(request => Amon2::Web::Request->new(+{}));
my $res = $c->render_json(+{"foo"=>"bar"});
is $res->status, 200;
is $res->header('Content-Type'), 'application/json; charset=utf-8';
is $res->content, '{"foo":"bar"}';
done_testing;

