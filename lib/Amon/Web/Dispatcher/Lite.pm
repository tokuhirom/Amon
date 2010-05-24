package Amon::Web::Dispatcher::Lite;
use strict;
use warnings;
use parent 'Amon::Web';
use Amon::Web::Declare;
use Router::Simple 0.04;
use Amon::Util qw/add_method/;

sub import {
    my $class = shift;
    strict->import;
    warnings->import;
    if (@_ > 0 && shift eq '-base') {
        my $caller = caller(0);

        my $router = Router::Simple->new();
        my $any = sub ($$;$) {
            my ($pattern, $dest, $opt) = do {
                if (@_ == 3) {
                    my ($methods, $pattern, $code) = @_;
                    ($pattern, {code => $code}, +{method => [ map { uc $_ } @$methods ]});
                } else {
                    my ($pattern, $code) = @_;
                    ($pattern, {code => $code}, +{});
                }
            };
            $router->connect(
                $pattern,
                $dest,
                $opt,
            );
        };
        # any [qw/get post delete/] => '/bye' => sub { ... };
        # any '/bye' => sub { ... };
        add_method($caller, 'any', $any);
        add_method($caller, 'get', sub {
            $any->([qw/GET HEAD/], $_[0], $_[1]);
        });
        add_method($caller, 'post', sub {
            $any->([qw/POST/], $_[0], $_[1]);
        });
        add_method($caller, 'dispatch', sub {
            my ($klass, $c) = @_;
            if (my $p = $router->match($c->request->env)) {
                return $p->{code}->($c, $p);
            } else {
                return res_404();
            }
        });

        Amon::Web::Declare->export_to_level(1);
    }
}

1;
__END__

=head1 NAME

Amon::Web::Dispatcher::Lite - Sinatra like dispatcher for Amon

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon::Web::Dispatcher::Lite -base;

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

