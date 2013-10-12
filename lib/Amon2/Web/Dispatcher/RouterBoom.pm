package Amon2::Web::Dispatcher::RouterBoom;
use strict;
use warnings;
use utf8;
use 5.008_001;
use Router::Boom;

sub import {
    my $class = shift;
    my %args = @_;
    my $caller = caller(0);

    my $router = Router::Boom->new();

    my $base =   $caller;
       $base =~ s!::Dispatcher\z!::C!;

    no strict 'refs';
    # functions
    #
    # get( '/path', 'Controller#action')
    # post('/path', 'Controller#action')
    # any( '/path', 'Controller#action')
    # get( '/path', sub { })
    # post('/path', sub { })
    # any( '/path', sub { })
    for my $method (qw(get post any)) {
        *{"${caller}::${method}"} = sub {
            my ($path, $dest) = @_;

            my %dest;
            if (ref $dest eq 'CODE') {
                $dest{code} = $dest;
            } else {
                my ($controller, $action) = split('#', $dest);
                $dest{controller} = $controller;
                $dest{action}     = $action if defined $action;
            }
            if ($method eq 'get') {
                $dest{method} = 'GET';
            } elsif ($method eq 'post') {
                $dest{method} = 'POST';
            }
            $router->add($path, \%dest);
        };
    }
    *{"${caller}::base"} = sub { $base = $_[0] };

    # class methods
    *{"${caller}::router"} = sub { $router };

    *{"${caller}::dispatch"} = sub {
        my ($class, $c) = @_;

        my $env = $c->request->env;
        if (my ($dest, $captured) = $class->router->match($env->{PATH_INFO})) {
            if ((!defined $dest->{method}) || $dest->{method} eq $env->{REQUEST_METHOD}) {
                my $res = eval {
                    if ($dest->{code}) {
                        return $dest->{code}->($c, $captured);
                    } else {
                        my $action = $captured->{action} || $dest->{action};
                        $c->{args} = $captured;
                        return "${base}::$dest->{controller}"->$action($c, $captured);
                    }
                };
                if ($@) {
                    if ($class->can('handle_exception')) {
                        return $class->handle_exception($c, $@);
                    } else {
                        print STDERR "$env->{REQUEST_METHOD} $env->{PATH_INFO} [$env->{HTTP_USER_AGENT}]: $@";
                        return $c->res_500();
                    }
                }
                return $res;
            } else {
                return $c->res_405();
            }
        } else {
            return $c->res_404();
        }
    };
}

1;
__END__

=head1 NAME

Amon2::Web::Dispatcher::RouterBoom - Router::Boom bindings

=head1 SYNOPSIS

    package MyApp::Web::Dispatcher;
    use Amon2::Web::Dispatcher::RouterBoom;

    get '/' => 'Foo#bar';

    finalize( base => 'MyApp::Web::C' );

=head1 DESCRIPTION

This is a router class for Amon2. It's based on Router::Boom.

=head1 DSL FUNCTIONS

=over 4

=item C<< get($path:Str, $destnation:Str) >>

=item C<< post($path:Str, $destnation:Str) >>

=item C<< any($path:Str, $destnation:Str) >>

    get  '/' => 'Root#index';
    get  '/:user' => 'User#show';
    any  '/:user/update' => 'User#update';
    post '/:user/blog/post' => 'Blog#post';

Add routes by DSL. First argument is the path pattern in Path::Boom rules.
Second argument is the destination method path.

Destination method pass is C<${class}#${method}> form.

=item C<< base($klass:Str) >>

    base 'My::App::Web::C';

You can specify the base class name for 'Root#index' style definition.

If you are write your dispatcher in following code, then the method for '/' is C<< My::App::Web::C::Root->index >>.

    base 'My::App::Web::C';
    get '/' => 'Root#index';

=item C<< get($path:Str, $destnation:CodeRef) >>

=item C<< post($path:Str, $destnation:CodeRef) >>

=item C<< any($path:Str, $destnation:CodeRef) >>

    get  '/' => sub {
        my ($c) = @_;
        ...
    };
    get  '/:user' => sub {
        my ($c, $args) = @_;
        $c->render(
            'user.tx' => {
                user => $args->{user},
            },
        );
    };

Add routes by DSL. First argument is the path pattern in Path::Boom rules.
Second argument is the destination code.

Callback function's first argument is the context object. Second is the captured values from the router.

=back

=head1 ROUTING RULES

Router::Boom's routing rule is really flexible. You can embed regexp in your rule.

=over 4

=item C<< /foo/bar >>

String literal matches strings.

=item C<< /:foo >>

C<< :foo >> matches C<< qr{[^/]} >>. It's captured.

=item C<< /{foo} >>

C<< {foo} >> is same as C<< :foo >>.

=item C<< /{foo:.*} >>

You can use the custom regexp for capturing.

=item C<< /* >>

C<< * >> is same as C<< {*:.*} >>.

=back

=head1 EXCEPTION HANDLER

You can customize the exception handler. You can define the special named method 'handle_exception'.

    package MyApp::Web::Dispatcher;

    sub handle_exception {
        my ($class, $c, $e) = @_;

        if (UNIVERSAL::isa($e, 'My::Exception::Validation')) {
            return $self->create_simple_status_page(400, 'Bad Request');
        } else {
            return $c->res_500();
        }
    }

=head1 SEE ALSO

L<Amon2>

