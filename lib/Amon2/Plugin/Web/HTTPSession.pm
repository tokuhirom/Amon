package Amon2::Plugin::Web::HTTPSession;
use strict;
use warnings;
use HTTP::Session;
use Amon2::Util;
use Plack::Util ();

sub init {
    my ($class, $c, $conf) = @_;

    my $state_conf = $conf->{state} or die "missing configuration : state";
    my $store_conf = $conf->{store} or die "missing configuration : store";
    my $state_code = $class->_load($state_conf, 'HTTP::Session::State');
    my $store_code = $class->_load($store_conf, 'HTTP::Session::Store');

    Amon2::Util::add_method($c, session => sub {
        my $self = shift;
        $self->{__PACKAGE__} ||= do {
            HTTP::Session->new(
                state   => $state_code->($self),
                store   => $store_code->($self),
                request => $self->request,
            );
        };
    });
    $c->add_trigger(AFTER_DISPATCH => sub {
        my ($self, $res) = @_;
        if (my $session = $self->{__PACKAGE__}) {
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
        my $store_class = Plack::Util::load_class($stuff, $namespace);
        my $store_obj;
        return sub {
            $store_obj ||= do {
                my $config ||= Amon2->context->config->{$store_class} || {};
                $store_class->new($config);
            };
        };
    }
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::HTTPSession - Plugin system for Amon2

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web -base;
    use HTTP::Session::Store::Memcached;
    __PACKAGE__->load_plugins(qw/Web::HTTPSession/ => {
        state => 'URI',
        store => sub {
            my ($c) = @_;
            HTTP::Session::Store::Memcached->new(
                memd => $c->get('Cache::Memcached::Fast')
            );
        },
    });

    package MyApp::C::Root;
    use strict;
    use warnings;
    use Amon2::Web::Declare;
    sub index {
        my $foo = c->session->get('foo');
        if ($foo) {
              c->session->set('foo' => $foo+1);
        } else {
              c->session->set('foo' => 1);
        }
    }

=head1 DESCRIPTION

HTTP::Session integrate to Amon2.

After load this plugin, you can get instance of HTTP::Session from C<c->session> method.

=head1 SEE ALSO

L<HTTP::Session>

=cut

