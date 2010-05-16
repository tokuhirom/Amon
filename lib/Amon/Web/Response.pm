package Amon::Web::Response;
use strict;
use warnings;
use HTTP::Headers;

# alias
sub code    { shift->status(@_) }
sub content { shift->body(@_)   }

sub new {
    my($class, $rc, $headers, $content) = @_;

    my $self = bless {}, $class;
    $self->status($rc)       if defined $rc;
    $self->headers($headers) if defined $headers;
    $self->body($content)    if defined $content;

    $self;
}

sub headers {
    my $self = shift;

    if (@_) {
        my $headers = shift;
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = HTTP::Headers->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = HTTP::Headers->new(%$headers);
        }
        return $self->{headers} = $headers;
    } else {
        return $self->{headers} ||= HTTP::Headers->new();
    }
}

sub header {
    my $self = shift;
    if (@_ == 2) {
        $self->headers->header(@_);
        return $self;
    } else {
        $self->headers->header(@_)
    }
}

sub finalize {
    my $self = shift;
    die "missing status" unless $self->status();

    return [
        $self->status,
        +[
            map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
        $self->_body,
    ];
}

sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q(""))) {
        return [ $body ];
    } else {
        return $body;
    }
}

sub content_type {
    my $self = shift;
    if (@_ == 1) {
        $self->headers->content_type(@_);
        return $self;
    } else {
        return $self->headers->content_type();
    }
}

sub status {
    my $self = shift;
    if (@_ == 1) {
        $self->{status} = $_[0];
        return $self;
    } else {
        return $self->{status};
    }
}

sub body {
    my $self = shift;
    if (@_ == 1) {
        $self->{body} = $_[0];
        return $self;
    } else {
        return $self->{body};
    }
}

1;
__END__

=head1 NAME

Amon::Web::Response - web response class for Amon

=head1 SYNOPSIS

    my $res = Amon::Web::Response->new(200, ['Content-Type' => 'text/plain'], 'OK');
    $res->finalize;

=head1 DESCRIPTION

This is response class for Amon.

=head1 METHODS

=over 4

=item new

  $res = Amon::Web::Response->new;
  $res = Amon::Web::Response->new($status);
  $res = Amon::Web::Response->new($status, $headers);
  $res = Amon::Web::Response->new($status, $headers, $body);

Creates a new Amon::Web::Response object.

=item status

  $res->status(200);
  $status = $res->status;

Sets and gets HTTP status code. C<code> is an alias.

=item headers

  $headers = $res->headers;
  $res->headers([ 'Content-Type' => 'text/html' ]);
  $res->headers({ 'Content-Type' => 'text/html' });
  $res->headers( HTTP::Headers->new );

Sets and gets HTTP headers of the response. Setter can take either an
array ref, a hash ref or L<HTTP::Headers> object containing a list of
headers.

=item body

  $res->body($body_str);
  $res->body([ "Hello", "World" ]);
  $res->body($io);

Gets and sets HTTP response body. Setter can take either a string, an
array ref, or an IO::Handle-like object. C<content> is an alias.

=item header

  $res->header('X-Foo' => 'bar');
  my $val = $res->header('X-Foo');

Shortcut for C<< $res->headers->header >>.

=item content_type, content_length, content_encoding

  $res->content_type('text/plain');
  $res->content_length(123);
  $res->content_encoding('gzip');

Shortcut for the equivalent get/set methods in C<< $res->headers >>.

=item redirect

  $res->redirect($url);
  $res->redirect($url, 301);

Sets redirect URL with an optional status code, which defaults to 302.

=item location

Gets and sets C<Location> header.

=back

