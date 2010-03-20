package Amon::Web::Lite::Dispatcher;
use strict;
use warnings;
use Amon::Web::Declare;

sub dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    my $router = $Amon::Web::Lite::_ROUTER{ref $c};
    if (my $p = $router->match($req->env)) {
        $c->{args} = $p;
        return $p->{code}->($c, $p);
    } else {
        return res_404();
    }
}

1;
