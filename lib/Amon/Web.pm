package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Try::Tiny;
use Amon::Web::Request;
use Amon::Util;
require Amon::Trigger;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    strict->import;
    warnings->import;

    # load classes
    Module::Pluggable::Object->new(
        'require' => 1, search_path => "${caller}::C"
    )->plugins;
    Amon::Util::load_class("${caller}::Dispatcher");

    my $base_class = $args{base_class} || do {
        local $_ = $caller;
        s/::Web(?:::.+)?$//;
        $_;
    };
    Amon::Util::load_class($base_class);

    my $request_class = $args{request_class} || 'Amon::Web::Request';
    Amon::Util::load_class($request_class);

    my $default_view_class = $args{default_view_class} or die "missing configuration: default_view_class";
    Amon::Util::load_class($default_view_class, "${base_class}::V");

    Amon::Trigger->export_to_level(1);

    no strict 'refs';
    *{"${caller}::app"}                = \&_app;
    *{"${caller}::default_view_class"} = sub { $default_view_class };
    *{"${caller}::base_class"}         = sub { $base_class };
    *{"${caller}::request_class"}      = sub { $request_class };
}

sub _app {
    my ($class, %args) = @_;
    my $base_class = $class->base_class;
    no strict 'refs';
    no warnings 'redefine';

    my $dispatcher = "${class}::Dispatcher";
    my $request_class = $class->request_class;

    return sub {
        my $env = shift;
        local *{"${base_class}::config"} = $args{config} ? sub { $args{config} } : *{"${base_class}::config"};
        try {
            my $req = $request_class->new($env);
            local $Amon::_context = $base_class->new(
                request  => $req,
                web_base => $class,
            );
            $dispatcher->dispatch($req);
        } catch {
            if (ref $_ && ref $_ eq 'ARRAY') {
                return $_;
            } else {
                local $SIG{__DIE__} = 'default'; # do not overwrite $trace in Middleware::StackTrace
                die $_; # rethrow
            }
        }
    };
}

1;
