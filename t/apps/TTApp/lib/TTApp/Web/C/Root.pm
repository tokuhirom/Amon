package TTApp::Web::C::Root;
use strict;
use warnings;
use Amon::Web::Declare;

sub index {
    render("index.tt", +{ name => 'john' });
}

1;
