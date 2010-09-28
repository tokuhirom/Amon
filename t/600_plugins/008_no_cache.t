use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Session', 'HTML::StickyQuery';
use Plack::Middleware::Lint;

{
    package MyApp;
    use parent qw/Amon2/;

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Tiffany;

    sub create_view { Tiffany->load('Text::MicroTemplate::File' ) }

    __PACKAGE__->load_plugins( 'Web::NoCache' );

    sub dispatch {
        my ($c) = @_;
        return $c->create_response(
            200, [], []
        );
    }
}

my $app = MyApp::Web->to_app();
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
$mech->get_ok('/');
is $mech->response->header('Cache-Control'), 'no-cache';
is $mech->response->header('Pragma'), 'no-cache';

done_testing;

