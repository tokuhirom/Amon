package SampleApp::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) =@_;
    $c->render("index.mt");
}

1;
