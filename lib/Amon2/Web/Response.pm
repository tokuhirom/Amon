package Amon2::Web::Response;
use strict;
use warnings;
use parent qw/Plack::Response/;


1;
__END__

=head1 NAME

Amon2::Web::Response - web response class for Amon2

=head1 SYNOPSIS

    my $res = Amon2::Web::Response->new(200, ['Content-Type' => 'text/plain'], 'OK');
    $res->finalize;

=head1 DESCRIPTION

This is response class for Amon2.

=head1 METHODS

=over 4

=item new

  $res = Amon2::Web::Response->new;
  $res = Amon2::Web::Response->new($status);
  $res = Amon2::Web::Response->new($status, $headers);
  $res = Amon2::Web::Response->new($status, $headers, $body);

Creates a new Amon2::Web::Response object.

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

