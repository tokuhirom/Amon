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
    use Amon -base;
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
}

{
    package MyApp::Web::C::Root;
    use Amon::Web::C;
    sub index { res(200, [], 'top') }

    package MyApp::Web::C::Blog;
    use Amon::Web::C;
    sub monthly {
        my ($class, $c, $args) = @_;
        res(200, [], "blog: $args->{year}, $args->{month}")
    }

    package MyApp::Web::C::Account;
    use Amon::Web::C;
    sub login { res(200, [], 'login') }

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher::RouterSimple -base;
    connect '/', {controller => 'Root', action => 'index'};
    connect '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'};
    submapper('/account/', {controller => 'Account'})
        ->connect('login', {action => 'login'});
}

my $app = MyApp::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('top');
$mech->get_ok('/blog/2010/04');
$mech->content_is("blog: 2010, 04");
$mech->get_ok('/account/login');
$mech->content_is("login");

done_testing;

