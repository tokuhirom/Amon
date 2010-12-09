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
    use Tiffany;
    sub create_view { Tiffany->load('Text::MicroTemplate::File') }
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
}

{
    package MyApp::Web::C::My;
    sub foo { Amon2->context->create_response(200, [], 'foo') }

    package MyApp::Web::C::Bar;
    sub poo { Amon2->context->create_response(200, [], 'poo') }

    package MyApp::Web::C::Root;
    sub index { Amon2->context->create_response(200, [], 'top') }
    sub sitemap { Amon2->context->create_response(200, [], 'sitemap') }

    package MyApp::Web::C::Blog;
    sub monthly {
        my ($class, $c, $args) = @_;
        Amon2->context->create_response(200, [], "blog: $args->{year}, $args->{month}")
    }

    package MyApp::Web::C::Account;
    use strict;
    use warnings;
    sub login { $_[1]->create_response(200, [], 'login') }

    package MyApp::Web::C::Baz;
    sub index { Amon2->context->create_response(200, [], 'top') }

    package MyApp::Web::C::low;
    sub index { Amon2->context->create_response(200, [], 'top') }

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterSimple;
    connect '/', {controller => 'Root', action => 'index'};
    connect '/my/foo', 'My#foo';
    connect '/bar/:action', 'Bar';
    connect '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'};
    submapper('/account/', {controller => 'Account'})
        ->connect('login', {action => 'login'});
    connect '/:action', { controller => 'Root' };
    connect '/:controller/', { action => 'index' };
    connect '/:controller/:action', {};
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
$mech->get_ok('/sitemap');
$mech->content_is("sitemap");
$mech->get_ok('/low/');
$mech->content_is("top");
$mech->get_ok('/baz/index2');
$mech->content_is("top");

done_testing;

