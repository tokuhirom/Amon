package Amon2::Web::Dispatcher::Lite;
use strict;
use warnings;
use parent 'Amon2::Web';
use Router::Simple 0.04;
use Router::Simple::Sinatraish;

sub import {
    my $class = shift;
    my $caller = caller(0);

    Router::Simple::Sinatraish->export_to_level(1);
    my $router = $caller->router;

    no strict 'refs';
    *{"$caller\::dispatch"} = sub {
        my ($klass, $c) = @_;
        if (my $p = $router->match($c->request->env)) {
            return $p->{code}->($c, $p);
        } else {
            return $c->res_404();
        }
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Web::Dispatcher::Lite - Sinatra like dispatcher for Amon2

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web::Dispatcher::Lite;

    get '/' => sub {
        render('index.mt');
    };
    get '/hello/:name' => sub {
        my ($c, $args) = @_;
        render('hello.mt', $args->{name});
    };

    1;

=head1 DESCRIPTION

B<It's in alpha quality>

