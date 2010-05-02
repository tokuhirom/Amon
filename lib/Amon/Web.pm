package Amon::Web;
use strict;
use warnings;
use Amon::Util;
use Amon::Util::Loader;
use Amon::Trigger;
use Amon::Container;

sub import {
    my $class = shift;
    if (@_>0 && shift eq '-base') {
        my %args = @_;
        my $caller = caller(0);

        strict->import;
        warnings->import;

        # load controller classes
        Amon::Util::Loader::load_all("${caller}::C");

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
        Amon::Util::load_class($default_view_class, "${base_name}::V");
        add_method($caller, 'default_view_class', sub { $default_view_class });

        no strict 'refs';
        unshift @{"${caller}::ISA"}, $base_name;
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }
sub request           { $_[0]->{request} }
sub req               { $_[0]->{request} }
sub pnotes            { $_[0]->{pnotes}  }
sub args              { $_[0]->{args}    }

sub redirect {
    my ($self, $location) = @_;
    my $url = do {
        if ($location =~ m{^https?://}) {
            $location;
        } else {
            my $url = $self->request->base;
            $url =~ s!/+$!!;
            $location =~ s!^/+([^/])!/$1!;
            $url .= $location;
        }
    };
    $self->response_class->new(
        302,
        ['Location' => $url],
        []
    );
}

sub to_app {
    my ($class, %args) = @_;

    my $self = $class->new(
         ($args{config} ? (config   => $args{config}) : ()),
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

sub uri_for {
    my ($self, $path, $query) = @_;
    my $root = $self->req->{env}->{SCRIPT_NAME} || '/';
    $root =~ s{([^/])$}{$1/};
    $path =~ s{^/}{};

    my @q;
    while (my ($key, $val) = each %$query) {
        $val = join '', map { /^[a-zA-Z0-9_.!~*'()-]$/ ? $_ : '%' . uc(unpack('H2', $_)) } split //, $val;
        push @q, "${key}=${val}";
    }
    $root . $path . (scalar @q ? '?' . join('&', @q) : '');
}

sub render {
    return shift->view()->make_response(@_);
}

sub render_partial {
    return shift->view()->render(@_);
}

sub view {
    my $self = shift;
    my $name = @_ == 1 ? $_[0] : $self->default_view_class;
       $name = "V::$name";
    my $klass = "@{[ $self->base_name ]}::$name";
    $self->{components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{$name} || +{};
        $klass->new($self, $config);
    };
}


# -------------------------------------------------------------------------
# pluggable things

sub load_plugins {
    my ($class, @args) = @_;
    for (my $i=0; $i<@args; $i+=2) {
        my ($module, $conf) = ($args[$i], $args[$i+1]);
        $class->load_plugin($module, $conf);
    }
}

sub load_plugin {
    my ($class, $module, $conf) = @_;
    $module = Amon::Util::load_class($module, 'Amon::Plugin');
    $module->init($class, $conf);
}

1;
