use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Session', 'HTML::StickyQuery';
use Plack::Middleware::Lint;

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use parent qw/Amon2/;

    package MyApp::Web::Dispatcher;
    sub dispatch {
        my ($class, $c) = @_;
        return $c->response_class->new(
            200, [], []
        );
    }

    package MyApp::Web;
    use parent qw/MyApp Amon2::Web/;
    __PACKAGE__->setup(
        view_class => 'Text::MicroTemplate::File',
    );
    __PACKAGE__->load_plugins( 'Web::NoCache' );
}

my $app = MyApp::Web->to_app();
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
$mech->get_ok('/');
is $mech->response->header('Cache-Control'), 'no-cache';
is $mech->response->header('Pragma'), 'no-cache';

done_testing;

