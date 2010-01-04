use strict;
use warnings;
use Plack::Request;
use Test::More;

BEGIN {
    $INC{'MyApp.pm'}      = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
}

{
    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher::HTTPxDispatcher;
    connect 'blog/:year/:month' => { controller => 'Blog', action => 'show' };
}

{
    package MyApp::Web::C::Blog;
    sub show {
        my ($class, $c, $args) = @_;
        [200, [], "YEAR: $args->{year}, MONTH: $args->{month}"];
    }
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        base_class => 'MyApp',
        dispatcher_class => 'Amon::Web::Dispatcher',
        default_view_class => 'MT',
    );
}

{
    package MyApp;
    use Amon -base;
}

my $c = MyApp::Web->bootstrap();

my $req = Plack::Request->new({PATH_INFO => '/blog/2009/01'});
$c->{request} = $req;
my $ret = MyApp::Web::Dispatcher->dispatch($c);
is $ret->[2], 'YEAR: 2009, MONTH: 01';

done_testing;
