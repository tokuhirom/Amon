package Amon2::Plugin::Web::Streaming;
use strict;
use warnings;
use utf8;

use Amon2::Util;
use Amon2::Web::Response::Callback;

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method(ref $c || $c, 'streaming', \&_streaming);
    Amon2::Util::add_method(ref $c || $c, 'streaming_json', \&_streaming_json);
}

sub _streaming {
    my ($self, $code) = @_;
    
    return Amon2::Web::Response::Callback->new(
        code => sub {
            $code->(@_);
        }
    );
}

sub _streaming_json {
    my ($self, $code) = @_;

    return Amon2::Web::Response::Callback->new(
        code => sub {
            my $respond = shift;
            my $writer = $respond->([200, ['Content-Type' => 'application/json;charset=utf-8']]);

            my $longpoll_ctx = Amon2::Plugin::Web::Streaming::Writer->new(
                $self,
                $writer
            );
            $code->($longpoll_ctx);
        }
    );
}

package Amon2::Plugin::Web::Streaming::Writer;

sub new {
    my ($class, $c, $writer) = @_;
    bless {ctx => $c, writer => $writer}, $class;
}

sub write_json {
    my ($self, $data) = @_;
    my $json = $self->{ctx}->render_json($data)->content;
    $self->{writer}->write($json);
}

sub close {
    my ($self) = @_;
    $self->{writer}->close();
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::Streaming - streaming support for Amon2

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugin(qw/Web::Streaming/);

    any '/poll' => sub {
        my $c = shift;
        return $c->streaming(sub {
            my $respond = shift;
            ...;
            $respond->write([200, [], ['OK']]);
        });
    };

    any '/poll_json' => sub {
        my $c = shift;
        return $c->streaming_json(sub {
            my $writer = shift;
            ...;
            $writer->write_json(+{ });
            $writer->close;
        });
    };


=head1 DESCRIPTION

This is an Amon2 plugin to support streaming.

You MUST use the HTTP server supporting psgi.streaming.

=head1 EXPORTED METHODS

=over 4

=item $c->streaming($code);

You can return delayed response for PSGI spec.

Argument for $code is C<< $respond >>. It's same as a argument for PSGI callback.

=item $c->streaming_json($code);

It's a short hand utility to publish streaming JSON.

The argument is instance of Amon2::Plugin::Web::Streaming::Writer.

=back

=head1 Amon2::Plugin::Streaming::Writer METHODS

=over 4

=item new

Do not create the instance directly.

=item $writer->write_json($data)

Write a $data as JSON for the socket.

=item $writer->close()

Close the socket.

=back


=head1 SEE ALSO

L<PSGI>

