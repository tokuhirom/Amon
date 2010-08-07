package TTApp::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index.tt", +{ name => 'john' });
}

1;
