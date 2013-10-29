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
    sub remove_index { Amon2->context->create_response(200, [], 'remove_top') }

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

    base 'MyApp::Web::C';

    get '/',        'Root#index';
    post '/',        'Root#post_index';
    delete_ '/',        'Root#remove_index';
    get '/my/foo', 'My#foo';
    get '/blog/{year}/{month}', 'Blog#monthly';
    get '/account/login', 'Account#login';
}

my $app = MyApp::Web->to_app();

sub Test::WWW::Mechanize::PSGI::delete_ok {
    my ($self, $url) = @_;
    my $request = HTTP::Request->new(DELETE => $url);
    my $res = $self->request($request);
    ::ok($res->code =~ /\A2..\z/, "DELETE $url");
}

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('top');
$mech->post_ok('/');
$mech->content_is('post_top');
$mech->delete_ok('/');
$mech->content_is('remove_top');
$mech->get_ok('/my/foo');
$mech->content_is('foo');
$mech->get_ok('/blog/2010/04');
$mech->content_is("blog: 2010, 04");
$mech->get_ok('/account/login');
$mech->content_is("login");

done_testing;

