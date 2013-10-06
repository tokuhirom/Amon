package <% $module %>::<% $moniker %>::Dispatcher;
use strict;
use warnings;
use utf8;
use Router::Simple::Declare;
use String::CamelCase qw(decamelize);
use Module::Find ();
use Module::Functions qw(get_public_functions);

# define roots here.
my $router = router {
    # connect '/' => {controller => 'Root', action => 'index', method => 'GET' };
};

my @controllers = Module::Find::useall('<% $module %>::<% $moniker %>::C');
{
    for my $controller (@controllers) {
        my $p0 = $controller;
        $p0 =~ s/^<% $module %>::<% $moniker %>::C:://;
        my $p1 = $p0 eq 'Root' ? '' : decamelize($p0) . '/';
        for my $method (get_public_functions($controller)) {
            my $p2 = $method eq 'index' ? '' : $method;
            my $path = "/$p1$p2";
            $router->connect($path => {
                controller => $p0,
                action     => $method,
            });
            print STDERR "map: $path => ${p0}::${method}\n" unless $ENV{HARNESS_ACTIVE};
        }
    }
}

sub dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $router->match($req->env)) {
        my $action = $p->{action};
        $c->{args} = $p;
        if ($p->{method} && $p->{method} ne $c->req->method) {
            return $c->create_response(403, ['Content-Type' => 'text/plain'], ['Method not allowed']);
        }
        "<% $module %>::<% $moniker %>::C::$p->{controller}"->$action($c, $p);
    } else {
        $c->res_404();
    }
}

1;
