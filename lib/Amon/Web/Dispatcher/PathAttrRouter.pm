package Amon::Web::Dispatcher::PathAttrRouter;
use strict;
use warnings;
use Path::AttrRouter;
use Amon::Web::Declare;

sub import {
    my $class = shift;
    if (@_ > 0 && shift eq '-base') {
        my %args = @_;
        my $caller = caller(0);

        my $search_path = $args{search_path} or die "missing search_path";
        my $router = Path::AttrRouter->new(search_path => $search_path);

        no strict 'refs';
        unshift @{"${caller}::ISA"}, $class;
        *{"${caller}::router"} = sub { $router };
    }
}

sub dispatch {
    my ($self, $c) = @_;
    my $m = $self->router->match($c->request->path_info);
    if ($m) {
        my $controller = $m->action->controller;
        my $meth = $m->action->name;
        return $controller->$meth($c, @{ $m->args }, @{ $m->captures });
    } else {
        return res_404();
    }
}

sub router { die "This is abstract method" }

1;
__END__

=head1 NAME

Amon::Web::Dispatcher::PathAttrRouter - Path::AttrRouter binding for Amon

=head1 SYNOPSIS

    package MyApp::Web::C;
    use base qw/Path::AttrRouter::Controller/;
    use Amon::Web::Declare;
    sub index :Path {
        my ($self, $c) = @_;
        res(200, [], 'index');
    }

    sub index2 :Path :Args(2) {
        my ($self, $c, $x, $y) = @_;
        res(200, [], "index2: $x, $y");
    }

    package MyApp::Web::C::Regex;
    use base qw/Path::AttrRouter::Controller/;
    use Amon::Web::Declare;

    sub index :Regex('^regex/(\d+)/(.+)') {
        my ($self, $c, $y, $m) = @_;
        res(200, [], "regexp: $y, $m");
    }

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher::PathAttrRouter -base => (
        search_path => 'MyApp::Web::C',
    );

=head1 DESCRIPTION

L<Path::Router> binding for Amon.L<Path::Router> provides L<Catalyst> like attribute router.

This is optional, and not maintained.Just experimental.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Path::AttrRouter>, L<http://github.com/typester/Path-AttrRouter>

