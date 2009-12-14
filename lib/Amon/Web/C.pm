package Amon::Web::C;
use strict;
use warnings;
use Amon::Web::Component;

sub import {
    strict->import;
    warnings->import;
    Amon::Web::Component->export_to_level(1);
}

1;
