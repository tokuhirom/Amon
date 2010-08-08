package Amon2::Web::Dispatcher::RouterSimple;
use strict;
use warnings;
use Router::Simple 0.03;

sub import {
    my $class = shift;
    my %args = @_;
    my $caller = caller(0);

    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;

    my $router = Router::Simple->new();

    no strict 'refs';
    # functions
    for my $meth (qw/connect submapper/) {
        *{"${caller}::${meth}"} = sub {
            $router->$meth(@_);
        };
    }
    # class methods
    for my $meth (qw/match as_string/) {
        *{"$caller\::${meth}"} = sub {
            my $self = shift;
            $router->$meth(@_)
        };
    }
    *{"$caller\::dispatch"} = \&_dispatch;
}

sub _dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $class->match($req->env)) {
        my $action = $req->method eq 'POST' ? "post_$p->{action}" : $p->{action};
        $c->{args} = $p;
        "@{[ ref Amon2->context ]}::C::$p->{controller}"->$action($c, $p);
    } else {
        $c->res_404();
    }
}

1;
__END__

=head1 NAME

Amon2::Web::Dispatcher::RouterSimple - Router::Simple binding for Amon2

=head1 SYNOPSIS

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterSimple;

=head1 DESCRIPTION

L<Router::Simple> binding for Amon2.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Router::Simple>

