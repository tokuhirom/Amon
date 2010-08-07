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
    use Amon2 -base;
}

{
    package MyApp::Web;
    use Amon2::Web -base => (
        default_view_class => 'Text::MicroTemplate::File',
    );
}

{
    package MyApp::Web::C::Root;
    use strict;
    use warnings;
    sub index { Amon2->context->response_class->new(200, [], 'top') }

    package MyApp::Web::C::Blog;
    use strict;
    use warnings;
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

