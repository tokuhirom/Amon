package Amon2::Web;
use strict;
use warnings;
use Amon2::Util;
use Amon2::Trigger;
use Encode ();
use Module::Find ();
use Plack::Util ();

sub import {
    my $class = shift;
    if (@_>0 && shift eq '-base') {
        my %args = @_;
        my $caller = caller(0);

        strict->import;
        warnings->import;

        # load controller classes
        Module::Find::useall("${caller}::C");

        my $dispatcher_class = $args{dispatcher_class} || "${caller}::Dispatcher";
        Plack::Util::load_class($dispatcher_class);
        Amon2::Util::add_method($caller, 'dispatcher_class', sub { $dispatcher_class });

        my $base_name = $args{base_name} || do {
            local $_ = $caller;
            s/::Web(?:::.+)?$//;
            $_;
        };
        Plack::Util::load_class($base_name);
        Amon2::Util::add_method($caller, 'base_name', sub { $base_name });

        my $request_class = $args{request_class} || 'Amon2::Web::Request';
        Plack::Util::load_class($request_class);
        Amon2::Util::add_method($caller, 'request_class', sub { $request_class });

        my $response_class = $args{response_class} || 'Amon2::Web::Response';
        Plack::Util::load_class($response_class);
        Amon2::Util::add_method($caller, 'response_class', sub { $response_class });

        my $default_view_class = $args{default_view_class} or die "missing configuration: default_view_class";
        Amon2::Util::add_method($caller, 'default_view_class', sub { $default_view_class });

        no strict 'refs';
        unshift @{"${caller}::ISA"}, $base_name;
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }
sub request           { $_[0]->{request} }
sub req               { $_[0]->{request} }
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

sub res_404 {
    my ($self) = @_;
    my $content = 'not found';
    $self->response_class->new(
        404,
        ['Content-Type' => 'text/plain', 'Content-Length' => length($content)],
        [$content]
    );
}

sub to_app {
    my ($class, %args) = @_;

    return sub {
        my ($env) = @_;
        my $req = $class->request_class->new($env);
        my $self = $class->new(
            request => $req,
            ($args{config} ? (config   => $args{config}) : ()),
        );

        no warnings 'redefine';
        local *Amon2::context = sub { $self };

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
        unless (ref $response->body) {
            $response->body(Encode::encode_utf8($response->body)) if utf8::is_utf8($response->body);
            $response->header('Content-Length' => length($response->body()))
                unless $response->header('Content-Length');
        }
        return $response->finalize;
    };
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
    my $self = shift;
    my $html = $self->view()->render(@_);
    $self->response_class->new(
        200,
        ['Content-Type' => $self->html_content_type],
        $html,
    );
}

sub render_partial {
    my $self = shift;
    my $html = $self->view()->render(@_);
    return $html;
}

sub view {
    my $self = shift;
    my $name = @_ == 1 ? $_[0] : $self->default_view_class;
    $self->{components}->{"View::$name"} ||= do {
        my $klass = Plack::Util::load_class($name, 'Tfall');
        my $config = $self->config()->{$klass};
        $klass->new($config);
    };
}


1;
