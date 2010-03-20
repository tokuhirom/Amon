package Amon::Web::Lite;
use strict;
use warnings;
use parent 'Amon::Web';
use Amon::Web::Declare;
use Router::Simple 0.04;
use Amon::Web::Lite::Dispatcher;

our %_ROUTER;

sub import {
    my $caller = caller(0);

    no strict 'refs';
    my $class = __PACKAGE__;
    for my $meth (qw/any get post/) {
        *{"${caller}::${meth}"} = *{"${class}::_${meth}"};
    }

    Amon::Web::Declare->export_to_level(1);
    $_ROUTER{$caller} = Router::Simple->new();
    push @_, dispatcher_class => 'Amon::Web::Lite::Dispatcher';
    goto &Amon::Web::import;
}

sub run {
    my ($self, $env) = @_;
    $self->SUPER::run($env);
}

sub _register {
    my ($caller, $pattern, $dest, $opt) = @_;
    $_ROUTER{$caller}->connect(
        $pattern,
        $dest,
        $opt,
    );
}

# any [qw/get post delete/] => '/bye' => sub { ... };
# any '/bye' => sub { ... };
sub _any($$;$) {
    my ($pattern, $dest, $opt) = do {
        if (@_ == 3) {
            my ($methods, $pattern, $code) = @_;
            ($pattern, {code => $code}, +{method => [ map { uc $_ } @$methods ]});
        } else {
            my ($pattern, $code) = @_;
            ($pattern, {code => $code}, +{});
        }
    };
    _register(scalar(caller 0), $pattern, $dest, $opt);
}

sub _get  {
    my ( $pattern, $code ) = @_;
    _register(
        scalar( caller 0 ),
        $pattern,
        { code   => $code },
        { method => [ 'GET', 'HEAD' ] }
    );
}
sub _post {
    my ( $pattern, $code ) = @_;
    _register(
        scalar( caller 0 ),
        $pattern,
        { code   => $code },
        { method => [ 'POST' ] }
    );
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon::Web::Lite -base;

    get '/' => sub {
        render('index.mt');
    };
    get '/hello/:name' => sub {
        my ($c, $args) = @_;
        render('hello.mt', $args->{name});
    };

    1;

=head1 DESCRPTION

B<It's in alpha quality>

