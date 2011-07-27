use strict;
use warnings;
use utf8;

package Amon2::Lite;
use parent qw/Amon2 Amon2::Web/;
use Router::Simple 0.04;
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;
use File::Spec;
use File::Basename qw(dirname);
use Data::Section::Simple ();
use Amon2::Config::Simple;

my $COUNTER;

sub import {
    my $class = shift;
    no strict 'refs';

    my $router = Router::Simple->new();
    my $caller = caller(0);

    my $base_class = 'Amon2::Lite::_child_' . $COUNTER++;
    {
        no warnings;
        unshift @{"$base_class\::ISA"}, qw/Amon2 Amon2::Web/;
        unshift @{"$caller\::ISA"}, $base_class;
    }

    *{"$caller\::router"} = sub { $router };

    # any [qw/get post delete/] => '/bye' => sub { ... };
    # any '/bye' => sub { ... };
    *{"$caller\::any"} = sub ($$;$) {
        my $pkg = caller(0);
        if (@_==3) {
            my ($methods, $pattern, $code) = @_;
            $router->connect(
                $pattern,
                {code => $code},
                { method => [ map { uc $_ } @$methods ] }
            );
        } else {
            my ($pattern, $code) = @_;
            $router->connect(
                $pattern,
                {code => $code},
            );
        }
    };

    *{"$caller\::get"} = sub {
        $router->connect($_[0], {code => $_[1]}, {method => ['GET', 'HEAD']});
    };

    *{"$caller\::post"} = sub {
        $router->connect($_[0], {code => $_[1]}, {method => ['POST']});
    };

    *{"${base_class}\::dispatch"} = sub {
        my ($c) = @_;
        if (my $p = $router->match($c->request->env)) {
            return $p->{code}->($c, $p);
        } else {
            return $c->res_404();
        }
    };

    my $tmpl_dir = File::Spec->catdir(dirname((caller(0))[1]), 'tmpl');
    *{"${base_class}::create_view"} = sub {
        # using lazy loading to read __DATA__ section.
        my $vpath = Data::Section::Simple->new($caller)->get_data_section();
        my $config = $caller->config->{'Text::Xslate'} || +{};
        my $xslate = Text::Xslate->new(+{
            'syntax'   => 'TTerse',
            'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
            'path'     => [ $vpath, $tmpl_dir ],
            'function' => {
                c        => sub { Amon2->context() },
                uri_with => sub { Amon2->context()->req->uri_with(@_) },
                uri_for  => sub { Amon2->context()->uri_for(@_) },
            },
            %$config,
        });
        no warnings 'redefine';
        *{"${caller}::create_view"} = sub { $xslate };
        $xslate;
    };

    if (-d File::Spec->catdir($caller->base_dir, 'config')) {
        *{"${base_class}::load_config"} = sub { Amon2::Config::Simple->load(shift) };
    } else {
        *{"${base_class}::load_config"} = sub { +{ } };
    }
}

1;
__END__

=head1 NAME

Amon2::Lite - Sinatra-ish

=head1 SYNOPSIS

    use Amon2::Lite;

    get '/' => sub {
        my ($c) = @_;
        return $c->render('index.tt');
    };

    __PACKAGE__->to_app();

    __DATA__

    @@ index.tt
    <!doctype html>
    <html>
        <body>Hello</body>
    </html>

=head1 DESCRIPTION

This is a Sinatra-ish wrapper for Amon2.

B<THIS MODULE IS BETA STATE. API MAY CHANGE WITHOUT NOTICE>.

=head1 FUNCTIONS

=over 4

=item any(\@methods, $path, \&code)

=item any($path, \&code)

Register new route for router.

=item get($path, $code->($c))

Register new route for router.

=item post($path, $code->($c))

Register new route for router.

=item __PACKAGE__->load_plugin($name, \%opts)

Load a plugin to the context object.

=item __PACKAGE__->to_app()

Create new PSGI application instance.

=back

=head1 FAQ

=over 4

=item How can I configure the options for Xslate?

You can provide a constructor arguments by configuration.
Write following lines on your app.psgi.

    sub config {
        +{
            'Text::Xslate' => {
                syntax => 'Kolon'
            }
        }
    }

=item How can I use other template engines instead of Text::Xslate?

You can use any template engine with Amon2::Lite. You can overwrite create_view method same as normal Amon2.

This is a example to use L<Text::MicroTemplate::File>.

    use Tiffany::Text::MicroTemplate::File;

    sub create_view {
        Tiffany::Text::MicroTemplate::File->new(+{
            include_path => ['./tmpl/']
        })
    }

=back

=head1 AUTHOR

Tokuhiro Matsuno

