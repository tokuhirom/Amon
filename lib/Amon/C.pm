package Amon::C;
use strict;
use warnings;
use Amon::Component;

sub import {
    strict->import;
    warnings->import;
    Amon::Component->export_to_level(1);
}

1;
