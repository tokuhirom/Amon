package Amon::Plugin::HTTPSession;
use strict;
use warnings;
use HTTP::Session;
use Amon::Util;

sub init {
    my ($class, $c, $conf) = @_;

    my $state_code = $class->_load($conf->{state}, 'HTTP::Session::State');
    my $store_code = $class->_load($conf->{store}, 'HTTP::Session::Store');

    $c->add_method(session => sub {
        my $self = shift;
        $self->pnotes->{session} ||= do {
            HTTP::Session->new(
                state   => $state_code->(),
                store   => $store_code->(),
                request => $self->request,
            );
        };
    });
    $c->add_trigger(AFTER_DISPATCH => sub {
        my ($self, $res) = @_;
        if (my $session = $self->pnotes->{session}) {
            $session->response_filter($res);
            $session->finalize();
        }
    });
}

sub _load {
    my ($class, $stuff, $namespace) = @_;
    if (ref $stuff) {
        if (ref $stuff eq 'CODE') {
            return $stuff;
        } else {
            return sub { $stuff };
        }
    } else {
        my $store_class = Amon::Util::load_class($stuff, $namespace);
        my $store_obj = $store_class->new();
        return sub { $store_obj };
    }
}

1;
