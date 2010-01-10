package Amon::Plugin::HTTPSession;
use strict;
use warnings;
use HTTP::Session;
use Amon::Util;

sub init {
    my ($class, $c, $conf) = @_;

    my $state_conf = $conf->{state} or die "missing configuration : state";
    my $store_conf = $conf->{store} or die "missing configuration : store";
    my $state_code = $class->_load($state_conf, 'HTTP::Session::State');
    my $store_code = $class->_load($store_conf, 'HTTP::Session::Store');

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
        my $store_obj;
        return sub {
            $store_obj ||= do {
                my $config ||= Amon->context->config->{$store_class} || {};
                $store_class->new($config);
            };
        };
    }
}

1;
__END__

=head1 NAME

Amon::Plugin::HTTPSession - Plugin system for Amon

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon::Web -base;
    __PACKAGE__->load_plugins(qw/HTTPSession/);

    package MyApp::C::Root;
    use Amon::Web::C;
    sub index {
        my $foo = c->session->get('foo');
        if ($foo) {
              c->session->set('foo' => $foo+1);
        } else {
              c->session->set('foo' => 1);
        }
    }

=head1 DESCRIPTION

HTTP::Session integrate to Amon.

After load this plugin, you can get instance of HTTP::Session from C<c->session> method.

=head1 SEE ALSO

L<HTTP::Session>

=cut

