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

    my $dispatcher_class = $args{dispatcher_class} || "${caller}::Dispatcher";
    Amon::Util::load_class($dispatcher_class);

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

    my $html_content_type = do {
        my $hct = $args{html_content_type};
        if ($hct) {
            ref $hct ? $hct : sub { $hct };
        } else {
            sub { 'text/html; charset=UTF-8' };
        }
    };

    my $encoding = do {
        my $encoding = $args{encoding};
        if ($encoding) {
            ref $encoding ? $encoding : sub { $encoding };
        } else {
            sub { 'utf-8' };
        }
    };

    Amon::Trigger->export_to_level(1);

    no strict 'refs';
    *{"${caller}::to_app"}             = \&_to_app;
    *{"${caller}::default_view_class"} = sub { $default_view_class };
    *{"${caller}::base_class"}         = sub { $base_class };
    *{"${caller}::request_class"}      = sub { $request_class };
    *{"${caller}::dispatcher_class"}   = sub { $dispatcher_class };
    *{"${caller}::encoding"}           = $encoding;
    *{"${caller}::html_content_type"}  = $html_content_type;
}

sub _to_app {
    my ($class, %args) = @_;
    my $base_class = $class->base_class;
    no strict 'refs';
    no warnings 'redefine';

    my $dispatcher    = $class->dispatcher_class;
    my $request_class = $class->request_class;

    return sub {
        my $env = shift;

        my $req = $request_class->new($env);
        my $c = $base_class->new(
            web_base => $class,
            config   => $args{config},
            request  => $req,
        );
        local $Amon::_context = $c;
        $dispatcher->dispatch($req, $c);
        my $res = $c->response()
                    or die "response is not generated";
        return $res;
    };
}

1;
