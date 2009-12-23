package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Try::Tiny;
use Amon;
use Amon::Web::Request;
use Amon::Util;
require Amon::Trigger;

our $_req;
our $_web_base;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    # load classes
    Module::Pluggable::Object->new(
        'require' => 1, search_path => "${caller}::C"
    )->plugins;
    Amon::Util::load_class("${caller}::Dispatcher");

    strict->import;
    warnings->import;

    my $base_class = $args{base_class} || do {
        local $_ = $caller;
        s/::Web(?:::.+)$//;
        $_;
    };
    Amon::Util::load_class($base_class);

    my $request_class = $args{request_class} || 'Amon::Web::Request';
    Amon::Util::load_class($request_class);

    my $default_view_class = $args{default_view_class} or die "missing configuration: default_view_class";
    Amon::Util::load_class($default_view_class);

    Amon::Trigger->export_to_level(1);

    no strict 'refs';
    *{"${caller}::app"}                = \&_app;
    *{"${caller}::default_view_class"} = sub { $default_view_class };
    *{"${caller}::base_class"}         = sub { $base_class };
    *{"${caller}::request_class"}      = sub { $request_class };
}

sub _app {
    my ($class, $config) = @_;
    my $base_class = $class->base_class;
    $config ||= {};

    my $dispatcher = "${class}::Dispatcher";
    my $request_class = $class->request_class;

    return sub {
        my $env = shift;
        try {
            local $Amon::_base = $base_class;
            local $Amon::_global_config = $config;
            local $Amon::_registrar = +{};
            local $_req = $request_class->new($env);
            local $_web_base = $class;
            $dispatcher->dispatch($_req);
        } catch {
            if (ref $_ && ref $_ eq 'ARRAY') {
                return $_;
            } else {
                die $_; # rethrow
            }
        }
    };
}

1;
