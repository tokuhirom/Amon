package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Amon::Util;
use Amon::Web::Base;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    strict->import;
    warnings->import;

    # load classes
    Module::Pluggable::Object->new(
        'require' => 1, search_path => "${caller}::C"
    )->plugins;

    my $dispatcher_class = $args{dispatcher_class} || "${caller}::Dispatcher";
    load_class($dispatcher_class);
    add_method($caller, 'dispatcher_class', sub { $dispatcher_class });

    my $base_class = $args{base_class} || do {
        local $_ = $caller;
        s/::Web(?:::.+)?$//;
        $_;
    };
    load_class($base_class);
    add_method($caller, 'base_class', sub { $base_class });

    my $request_class = $args{request_class} || 'Amon::Web::Request';
    load_class($request_class);
    add_method($caller, 'request_class', sub { $request_class });

    my $default_view_class = $args{default_view_class} or die "missing configuration: default_view_class";
    load_class($default_view_class, "${base_class}::V");
    add_method($caller, 'default_view_class', sub { $default_view_class });

    no strict 'refs';
    unshift @{"${caller}::ISA"}, "Amon::Web::Base";
}

1;
