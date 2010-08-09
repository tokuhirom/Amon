package Amon2::Web;
use strict;
use warnings;
use Amon2::Util ();
use Amon2::Trigger qw/add_trigger call_trigger get_trigger_code/;
use Encode ();
use Module::Find ();
use Plack::Util ();
use URI::Escape ();
use Tiffany;

sub setup {
    my $class = shift;
    my %args = @_;

    # load controller classes
    Module::Find::useall("${class}::C");

    my $dispatcher_class = $args{dispatcher_class} || "${class}::Dispatcher";
    Plack::Util::load_class($dispatcher_class);
    Amon2::Util::add_method($class, 'dispatcher_class', sub { $dispatcher_class });

    my $request_class = $args{request_class} || 'Amon2::Web::Request';
    Plack::Util::load_class($request_class);
    Amon2::Util::add_method($class, 'request_class', sub { $request_class });

    my $response_class = $args{response_class} || 'Amon2::Web::Response';
    Plack::Util::load_class($response_class);
    Amon2::Util::add_method($class, 'response_class', sub { $response_class });

    # view object is cache-able.
    my $view_class = $args{view_class} or die "missing configuration: view_class";
    my $config = $class->config()->{$view_class};
    my $view = Tiffany->load($view_class, $config);
    Amon2::Util::add_method($class, 'view', sub { $view }); # cache
}

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }
sub request           { $_[0]->{request} }
sub req               { $_[0]->{request} }

sub redirect {
    my ($self, $location) = @_;
    my $url = do {
        if ($location =~ m{^https?://}) {
            $location;
        } else {
            my $url = $self->request->base;
            $url =~ s{/+$}{};
            $location =~ s{^/+([^/])}{/$1};
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
    my ($class, ) = @_;

    return sub {
        my ($env) = @_;
        my $req = $class->request_class->new($env);
        my $self = $class->new(
            request => $req,
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
        $val = URI::Escape::uri_escape(Encode::encode($self->encoding, $val));
        push @q, "${key}=${val}";
    }
    $root . $path . (scalar @q ? '?' . join('&', @q) : '');
}

sub render {
    my $self = shift;
    my $html = $self->view()->render(@_);

    for my $code ($self->get_trigger_code('HTML_FILTER')) {
        $html = $code->($html);
    }

    $html = Encode::encode($self->encoding, $html);

    return $self->response_class->new(
        200,
        ['Content-Type' => $self->html_content_type, 'Content-Length' => length($html)],
        $html,
    );
}

1;
