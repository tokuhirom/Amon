use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'Router::Simple';

{
    package MyApp;
    use parent qw/Amon2/;
	__PACKAGE__->make_local_context();
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
}

{
    package MyApp::Web::C::My;
    sub foo { $_[1]->create_response(200, [], 'foo') }

    package MyApp::Web::C::Bar;
    sub poo { $_[1]->create_response(200, [], 'poo') }

    package MyApp::Web::C::Root;
    sub index { $_[1]->create_response(200, [], 'top') }

    package MyApp::Web::C::Blog;
    sub monthly {
        my ($class, $c, $args) = @_;
        $c->create_response(200, [], "blog: $args->{year}, $args->{month}")
    }

    package MyApp::Web::C::Account;
    use strict;
    use warnings;
    sub login { $_[1]->create_response(200, [], 'login') }

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterSimple;

    ::isa_ok __PACKAGE__->router(), 'Router::Simple';

    connect '/', {controller => 'Root', action => 'index'};
    connect '/my/foo', 'My#foo';
    connect '/bar/:action', 'Bar';
    connect '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'};
    submapper('/account/', {controller => 'Account'})
        ->connect('login', {action => 'login'});
}

my $app = MyApp::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('top');
$mech->get_ok('/my/foo');
$mech->content_is('foo');
$mech->get_ok('/bar/poo');
$mech->content_is('poo');
$mech->get_ok('/blog/2010/04');
$mech->content_is("blog: 2010, 04");
$mech->get_ok('/account/login');
$mech->content_is("login");

done_testing;

