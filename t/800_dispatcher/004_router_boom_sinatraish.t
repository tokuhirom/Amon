use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
}

{
    package MyApp::Web::C::My;
    sub foo { Amon2->context->create_response(200, [], 'foo') }

    package MyApp::Web::C::Root;
    sub index { Amon2->context->create_response(200, [], 'top') }
    sub post_index { Amon2->context->create_response(200, [], 'post_top') }

    package MyApp::Web::C::Blog;
    sub monthly {
        my ($class, $c, $args) = @_;
        Amon2->context->create_response(200, [], "blog: $args->{year}, $args->{month}")
    }

    package MyApp::Web::C::Account;
    use strict;
    use warnings;
    sub login { $_[1]->create_response(200, [], 'login') }

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterBoom;

    ::isa_ok __PACKAGE__->router(), 'Router::Boom::Method';

    get '/', sub { $_[0]->create_response(200, [], 'top') };
    post '/', sub { $_[0]->create_response(200, [], 'post_top') };
    get '/my/foo', sub { $_[0]->create_response(200, [], 'foo') };
    get '/blog/{year}/{month}', sub {
        my ($c, $captured) = @_;
        $c->create_response(200, [], "blog: $captured->{year}, $captured->{month}")
    };
    get '/account/login', sub {
        my ($c, $captured) = @_;
        $c->create_response(200, [], 'login');
    };
}

my $app = MyApp::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('top');
$mech->head_ok('/');
$mech->post_ok('/');
$mech->content_is('post_top');
$mech->get_ok('/my/foo');
$mech->content_is('foo');
$mech->get_ok('/blog/2010/04');
$mech->content_is("blog: 2010, 04");
$mech->get_ok('/account/login');
$mech->content_is("login");

done_testing;

