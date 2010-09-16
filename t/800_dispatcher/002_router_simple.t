use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

BEGIN {
    $INC{"MyApp.pm"}                = __FILE__;
    $INC{"MyApp/V/MT.pm"}           = __FILE__;
    $INC{"MyApp/Web/Dispatcher.pm"} = __FILE__;
};

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
}

{
    package MyApp::Web::C::My;
    sub foo { Amon2->context->response_class->new(200, [], 'foo') }

    package MyApp::Web::C::Bar;
    sub poo { Amon2->context->response_class->new(200, [], 'poo') }

    package MyApp::Web::C::Root;
    sub index { Amon2->context->response_class->new(200, [], 'top') }

    package MyApp::Web::C::Blog;
    sub monthly {
        my ($class, $c, $args) = @_;
        Amon2->context->response_class->new(200, [], "blog: $args->{year}, $args->{month}")
    }

    package MyApp::Web::C::Account;
    use strict;
    use warnings;
    sub login { $_[1]->response_class->new(200, [], 'login') }

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterSimple;
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

