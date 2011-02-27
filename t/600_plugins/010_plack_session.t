use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'Plack::Session';
use Plack::Middleware::Lint;
use Plack::Middleware::Session;
use Plack::Builder;

{
    package MyApp;
    use parent qw/Amon2/;
    sub load_config { +{} }

    package MyApp::Web;
    use Amon2::Web;
    our @ISA = qw/MyApp Amon2::Web/;

    sub dispatch {
        my $c = shift;
        my $cnt = $c->session->get('cnt' || 0);
        ++$cnt;
        $c->session->set('cnt' => $cnt);
        return $c->create_response(200, [], [$cnt]);
    }

    __PACKAGE__->load_plugins('Web::PlackSession');
}

my $app = builder {
    enable 'Session';
    enable 'Lint';

    MyApp::Web->to_app()
};
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app, );
$mech->get_ok('/');
is $mech->content(), '1';
$mech->get_ok('/');
is $mech->content(), '2';

done_testing;
