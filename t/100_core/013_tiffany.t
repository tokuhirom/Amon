use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires qw/Tiffany Test::WWW::Mechanize::PSGI/;

package MyApp;
use parent qw/Amon2/;

package MyApp::Web;
use Amon2::Web;
our @ISA = qw/MyApp Amon2::Web/;

sub create_view { Tiffany->load('Text::MicroTemplate::File', {include_path => ['t/tmpl/']}) }

sub dispatch {
    my $c = shift;
    $c->render('foo.mt', 'world');
}

package main;

my $app = MyApp::Web->to_app();
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('http://localhost/');
$mech->content_like(qr/Hello, world!/);

done_testing;

