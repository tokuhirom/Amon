package Amon::Web::Dispatcher;
use strict;
use warnings;
use Amon::Web::Component;
use base 'Exporter';
our @EXPORT = qw/call/;

sub import {
    strict->import;
    warnings->import;
    Amon::Web::Component->export_to_level(1);
    __PACKAGE__->export_to_level(1);
}

sub call {
    my ($controller, $action, @args) = @_;
    "${Amon::_base}::Web::C::$controller"->$action(@args);
}

1;
