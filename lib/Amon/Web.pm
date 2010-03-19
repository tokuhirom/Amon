package Amon::Web;
use strict;
use warnings;
use Module::Pluggable::Object;
use Amon::Util;
use Amon::Trigger;
use Amon::Container;

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

        my $base_name = $args{base_name} || do {
            local $_ = $caller;
            s/::Web(?:::.+)?$//;
            $_;
        };
        load_class($base_name);
        add_method($caller, 'base_name', sub { $base_name });

        my $request_class = $args{request_class} || 'Amon::Web::Request';
        load_class($request_class);
        add_method($caller, 'request_class', sub { $request_class });

        my $response_class = $args{response_class} || 'Amon::Web::Response';
        load_class($response_class);
        add_method($caller, 'response_class', sub { $response_class });

        my $default_view_class = $args{default_view_class} or die "missing configuration: default_view_class";
        load_class($default_view_class, "${base_name}::V");
        add_method($caller, 'default_view_class', sub { $default_view_class });

        no strict 'refs';
        unshift @{"${caller}::ISA"}, $base_name;
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }
sub request           { $_[0]->{request} }
sub pnotes            { $_[0]->{pnotes}  }
sub args              { $_[0]->{args}    }

sub to_app {
    my ($class, %args) = @_;

    my $self = $class->new(
        config   => $args{config},
    );
    return sub { $self->run(shift) };
}

sub run {
    my ($self, $env) = @_;

    my $req = $self->request_class->new($env);
    local $self->{request} = $req;
    local $self->{pnotes}  = +{};
    local $Amon::_context = $self;

    my $response;
    for my $code ($self->get_trigger_code('BEFORE_DISPATCH')) {
        $response = $code->($self);
        last if $response;
    }
    unless ($response) {
        $response = $self->dispatcher_class->dispatch($self)
            or die "response is not generated";
    }
    $self->call_trigger('AFTER_DISPATCH' => $response);
    return $response->finalize;
}

1;
