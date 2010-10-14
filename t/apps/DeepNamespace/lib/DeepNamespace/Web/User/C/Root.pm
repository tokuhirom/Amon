package DeepNamespace::Web::User::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index");
}

1;
