package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Amon::Util;
use Amon::Web::Base;

sub import {
    my $class = shift;
    if (@_>0 && shift eq '-base') {
        my %args = @_;
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
        unshift @{"${caller}::ISA"}, $base_class;
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }
sub request           { $_[0]->{request} }

sub to_app {
    my ($class, %args) = @_;

    my $dispatcher    = $class->dispatcher_class;
    my $request_class = $class->request_class;

    return sub {
        my $env = shift;

        my $req = $request_class->new($env);
        my $c = $class->new(
            config   => $args{config},
            request  => $req,
        );
        local $Amon::_context = $c;

        my $response;
        for my $code ($c->get_trigger_code('BEFORE_DISPATCH')) {
            $response = $code->();
            last if $response;
        }
        unless ($response) {
            $response = $dispatcher->dispatch($req, $c)
                    or die "response is not generated";
        }
        $c->call_trigger('AFTER_DISPATCH' => $response);

        $c->_destroy_me();

        return $response;
    };
}


sub _destroy_me {
    my $self = shift;
    # paranoia: guard against cyclic reference
    delete $self->{$_} for keys %$self;
}

1;
