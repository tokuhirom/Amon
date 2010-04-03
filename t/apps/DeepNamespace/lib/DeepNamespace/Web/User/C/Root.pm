package DeepNamespace::Web::User::C::Root;
use strict;
use warnings;
use Amon::Web::Declare;

sub index {
    render("index.mt");
}

1;
