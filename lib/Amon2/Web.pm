package Amon2::Web;
use strict;
use warnings;
use Amon2::Util ();
use Amon2::Trigger qw/add_trigger call_trigger get_trigger_code/;
use Encode ();
use Plack::Util ();
use URI::Escape ();
use Amon2::Web::Request;
use Amon2::Web::Response;
use Scalar::Util ();
use Plack::Util;

# -------------------------------------------------------------------------
# Hook points:
# You can override these methods.
sub create_request  { Amon2::Web::Request->new($_[1], $_[0]) }
sub create_response { shift; Amon2::Web::Response->new(@_) }
sub create_view     { die "This is abstract method: create_view" }
sub dispatch        { die "This is abstract method: dispatch"    }

sub html_content_type { 'text/html; charset=UTF-8' }
BEGIN {
    my $encoding = Encode::find_encoding('utf-8') || die;
    sub encoding          { $encoding }
}

sub session {
    my $self = shift;
    my $klass = ref $self || $self;

    require Plack::Session;
    no strict 'refs';
    *{"${klass}::session"} = sub {
        my $self = shift;
        $self->{session} ||= Plack::Session->new($self->request->env);
    };

    return $self->session();
}

# -------------------------------------------------------------------------
# Attributes:
sub request           { $_[0]->{request} }
sub req               { $_[0]->{request} }

# -------------------------------------------------------------------------
# Methods:

sub redirect {
    my ($self, $location, $params) = @_;
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
    if (my $ref_params = ref $params) {
        if ($ref_params eq 'ARRAY') {
            my $uri = URI->new($url);
            $uri->query_form($uri->query_form, map { Encode::encode($self->encoding, $_) } @$params);
            $url = $uri->as_string;
        } elsif ($ref_params eq 'HASH') {
            my @ary;
            my $encoding = $self->encoding;
            while (my ($k, $v) = each %$params) {
                push @ary, Encode::encode($encoding, $k);
                push @ary, Encode::encode($encoding, $v);
            }
            my $uri = URI->new($url);
            $uri->query_form($uri->query_form, @ary);
            $url = $uri->as_string;
        }
    }
    return $self->create_response(
        302,
        ['Location' => $url],
        []
    );
}

sub create_simple_status_page {
    my ($self, $code, $message) = @_;
    my $codestr = Plack::Util::encode_html($code);
       $message = Plack::Util::encode_html($message);
    my $content = <<"...";
<!doctype html>
<html>
    <head>
        <meta charset=utf-8 />
        <title>$codestr $message</title>
        <style type="text/css">
            body {
                text-align: center;
                font-family: 'Menlo', 'Monaco', Courier, monospace;
                background-color: whitesmoke;
                padding-top: 10%;
            }
            .number {
                font-size: 800%;
                font-weight: bold;
                margin-bottom: 40px;
            }
            .message {
                font-size: 400%;
            }
        </style>
    </head>
    <body>
        <div class="number">$codestr</div>
        <div class="message">$message</div>
    </body>
</html>
...
    $self->create_response(
        $code,
        [
            'Content-Type' => 'text/html; charset=utf-8',
            'Content-Length' => length($content),
        ],
        [$content]
    );
}

sub res_403 {
    my ($self) = @_;
    return $self->create_simple_status_page(403, 'Forbidden');
}

sub res_404 {
    my ($self) = @_;
    return $self->create_simple_status_page(404, 'File Not Found');
}

sub res_405 {
    my ($self) = @_;
    return $self->create_simple_status_page(405, 'Method Not Allowed');
}

sub res_500 {
    my ($self) = @_;
    return $self->create_simple_status_page(500, 'Internal Server Error');
}

sub to_app {
    my ($class, ) = @_;
    return sub { $class->handle_request(shift) };
}

sub handle_request {
    my ($class, $env) = @_;

    my $req = $class->create_request($env);
    my $self = $class->new(
        request => $req,
    );
    my $guard = $self->context_guard();

    my $response;
    for my $code ($self->get_trigger_code('BEFORE_DISPATCH')) {
        $response = $code->($self);
        goto PROCESS_END if Scalar::Util::blessed($response) && $response->isa('Plack::Response');
    }
    $response = $self->dispatch() or die "cannot get any response";
PROCESS_END:
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
        $val = URI::Escape::uri_escape(Encode::encode($self->encoding, $val));
        push @q, "${key}=${val}";
    }
    $root . $path . (scalar @q ? '?' . join('&', @q) : '');
}

sub render {
    my $self = shift;
    my $html = $self->create_view()->render(@_);

    for my $code ($self->get_trigger_code('HTML_FILTER')) {
        $html = $code->($self, $html);
    }

    $html = $self->encode_html($html);

    return $self->create_response(
        200,
        [
            'Content-Type'   => $self->html_content_type,
            'Content-Length' => length($html)
        ],
        $html,
    );
}

# You can override this method on your application.
sub encode_html {
    my ($self, $html) = @_;
    return Encode::encode($self->encoding, $html);
}

1;
__END__

=head1 NAME

Amon2::Web - Web Application Base.

=head1 SYNOPSIS

    package MyApp;
    use parent qw/Amon2/;

    package MyApp::Web;
    use parent qw/MyApp Amon2::Web/;

=head1 DESCRIPTION

This is a web application base class.

=head1 METHODS

=over 4

=item C<< $c->create_request() >>

Create new request object from C<< $c >>.

You can override this method to change request object's class.

=item C<< $c->create_response($code, \@headers, \@body) >>

Create new response object.

You can override this method to change response object's class.

=item C<< $c->create_view() >>

Create new view object. View object should have C<< $view->render(@_) >> method.

You can override this method to change view object's class.

=item C<< $c->dispatch() : Plack::Response >>

Do dispatch request. This method must return instance of L<Plack::Response>.

You can override this method to change behavior.

=item C<< $c->html_content_type() : Str >>

Returns default Content-Type value for the HTML response.

You can override this method to change behavior.

=item C<< $c->request() : Plack::Request >>

=item C<< $c->req() : Plack::Request >>

This is a accessor method to get the request object in this context.

=item C<< $c->redirect($location : Str, \%parameters) : Plack::Response >>

Create a response object to redirect for C< $location > with C<< \%parameters >>.

    $c->redirect('/foo', +{bar => 3})

is same as following(if base URL is http://localhost:5000/)

    $c->create_response(302, [Location => 'http://localhost:5000/foo?bar=3'])

=item C<< $c->res_403() >>

Create new response object which has 403 status code.

=item C<< $c->res_404() >>

Create new response object which has 404 status code.

=item C<< $c->res_405() >>

Create new response object which has 405 status code.

=item C<< $c->create_simple_status_page($code, $message) >>

Create a new response object which represents specified status code.

=item C<< MyApp->to_app() : CodeRef >>

Create an instance of PSGI application.

=item C<< $c->uri_for($path: Str, \%args) : Str >>

Create URI from C<< $path >> and C<< \%args >>.

This method returns relative URI.

=item C<< $c->render($tmpl[, @args|%args]) : Plack::Web::Response >>

This method renders HTML.

=item C<< $c->encoding() >>

Return a encoding object using C<< Encode::find_encoding() >>.

You can override this method to change behavior.

=item C<< $c->encode_html($html) : Str >>

This method encodes HTML from bytes.

You can override this method to change behavior.

=back
