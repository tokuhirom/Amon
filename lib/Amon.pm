package Amon;
use strict;
use warnings;
use Module::Pluggable::Object;
use Plack::Request;
use UNIVERSAL::require;
use Amon::V;
use Try::Tiny;

our $VERSION = 0.01;

our $_req;
our $_base;
our $_basedir;
our $_global_config;

sub import {
    my $caller = caller(0);

    # load classes
    Module::Pluggable::Object->new(
        'require' => 1, search_path => "${caller}\::C"
    )->plugins;
    "${caller}::V::Context"->use or die $@;
    "${caller}::Dispatcher"->use or die $@;

    strict->import;
    warnings->import;

    no strict 'refs';
    *{"${caller}::app"} = \&_app;
    *{"${caller}::add_trigger"} = \&_add_trigger;
    *{"${caller}::call_trigger"} = \&_call_trigger;
}

sub _app {
    my ($class, $basedir, $config) = @_;
    $basedir ||= './';

    my $dispatcher = "${class}::Dispatcher";

    return sub {
        my $env = shift;
        try {
            local $_basedir = $basedir;
            local $_req = Plack::Request->new($env);
            local $_base = $class;
            local $_global_config = $config; 
            my $rule = $dispatcher->match($_req);
            my $action = $rule->{action};
            my $controller = "${class}::C::" . $rule->{controller};
            return $controller->$action($rule);
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
__END__

=head1 NAME

Amon - lightweight web application framework

=head1 SYNOPSIS

    $ amon-setup.pl MyApp

=head1 Point

    Fast
    Easy to use

