package Amon2::Web::Dispatcher::RouterSimple;
use strict;
use warnings;
use Router::Simple 0.03;

sub import {
    my $class = shift;
    my %args = @_;
    my $caller = caller(0);

    my $router = Router::Simple->new();

    no strict 'refs';
    # functions
    *{"${caller}::connect"} = sub {
        if (@_ == 2 && !ref $_[1]) {
            my ($path, $dest_str) = @_;
            my ($controller, $action) = split('#', $dest_str);
            my %dest;
            $dest{controller} = $controller;
            $dest{action} = $action if defined $action;
            $router->connect($path, \%dest);
        } else {
            $router->connect(@_);
        }
    };
    *{"${caller}::submapper"} = sub {
        $router->submapper(@_);
    };
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
        my $action = $p->{action};
        $c->{args} = $p;
        for my $controller ( ucfirst($p->{controller}), $p->{controller} ) {
            return
                "@{[ ref Amon2->context ]}::C::$controller"->$action($c, $p)
                    if eval { "@{[ ref Amon2->context ]}::C::$controller"->can($action) };
        }
        $c->res_404();
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
    connect '/'           => 'Root#index';
    connect '/my/'        => 'My#index';
    connect '/my/:action' => 'My';
    1;

=head1 DESCRIPTION

L<Router::Simple> binding for Amon2.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Router::Simple>

