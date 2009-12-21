package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Try::Tiny;
use Amon;
use Amon::Web::Request;
use Amon::Util;

our $_req;

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

    (my $base_class = $caller) =~ s/::Web//;

    my $view_class = $args{view_class} or die "missing configuration: view_class";
    $view_class = ($view_class =~ s/^\+// ? $view_class : "Amon::V::$view_class");
    Amon::Util::load_class($view_class);
    $view_class->import($base_class);

    no strict 'refs';
    *{"${caller}::app"} = \&_app;
    *{"${caller}::add_trigger"} = \&_add_trigger;
    *{"${caller}::call_trigger"} = \&_call_trigger;
    *{"${caller}::view_class"} = sub { $view_class };
}

sub _app {
    my ($class, $basedir, $config) = @_;
    (my $base_class = $class) =~ s/::Web//;
    $basedir ||= './';
    $config ||= {};

    my $dispatcher = "${base_class}::Web::Dispatcher";

    return sub {
        my $env = shift;
        try {
            local $Amon::_basedir = $basedir;
            local $Amon::_base = $base_class;
            local $Amon::_global_config = $config;
            local $Amon::_registrar = +{};
            local $_req = Amon::Web::Request->new($env);
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

=item MyApp->add_trigger($hook, $code);

register hook.

=cut
sub _add_trigger {
    my ($class, $hook, $code) = @_;
    no strict 'refs';
    push @{${"${class}::_trigger"}->{$hook}}, $code;
}

=item MyApp->call_trigger($hook, @args);

internal use only

=cut
sub _call_trigger {
    my ($class, $hook, @args) = @_;
    no strict 'refs';
    for my $code (@{${"${class}::_trigger"}->{$hook} || []}) {
        $code->(@args);
    }
}

1;
