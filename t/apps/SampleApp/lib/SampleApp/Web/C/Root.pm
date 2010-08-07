package SampleApp::Web::C::Root;
use strict;
use warnings;
use Amon2::Web::Declare;

sub index {
    render("index.mt");
}

1;
