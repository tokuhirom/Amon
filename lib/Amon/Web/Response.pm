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
