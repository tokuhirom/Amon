package Amon2::Web::Response::Callback;
use strict;
use warnings;
use utf8;
use Carp ();
use HTTP::Headers ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    $args{code} || Carp::croak "Missing mandatory parameter: code";
    bless {
        headers => HTTP::Headers->new,
        %args
    }, $class;
}
sub header {
    my $self = shift;
    $self->headers->header(@_);
}
sub headers { $_[0]->{headers} }
sub finalize {
    my $self = shift;
    delete $self->{headers};

    # Defence from HTTP Header Splitting.
    my $code = delete $self->{code};
    return sub {
        my $responder = shift;
        $code->(
            sub {
                my @copy = @{ $_[0]->[1] };
                for (my ($key, $val) = splice(@copy, 0, 2)) {
                    if ($val =~ /[\000-\037]/) {
                        die("Response headers MUST NOT contain characters below octal \037\n");
                    }
                }
                return $responder->(@_);
            }
        );
    };
}


1;
__END__

=head1 NAME

Amon2::Web::Response::Callback - [EXPERIMENTAL]callback style psgi response for Amon2

=head1 SYNOPSIS

    use Amon2::Lite;

    any '/cb' => sub {
        my $c = shift;
        Amon2::Web::Response::Callback->new(
            code => sub {
                my $respond = shift;
                $respond->([200, [], []]);
            }
        );
    };

=head1 DESCRIPTION

This module provides a response object for delayed response/streaming body.

You can embed the AE support, streaming support, etc on Amon2 with this module.

=head1 SEE ALSO

L<Tatsumaki>

