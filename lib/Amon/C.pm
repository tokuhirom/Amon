package Amon::C;
use strict;
use warnings;
use Amon::Component;

sub import {
    strict->import;
    warnings->import;

    my $caller = caller(0);
    no strict 'refs';
    *{"$caller\::req"} = sub { $Amon::_req };
    Amon::Component->export_to_level(1);
}

1;
