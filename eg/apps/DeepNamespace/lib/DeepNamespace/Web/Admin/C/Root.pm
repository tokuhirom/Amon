package DeepNamespace::Web::Admin::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index");
}

1;
