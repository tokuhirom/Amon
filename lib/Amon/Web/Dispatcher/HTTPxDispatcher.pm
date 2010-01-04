package Amon::Web::Dispatcher::HTTPxDispatcher;
use strict;
use warnings;
use base qw/Exporter/;
require HTTPx::Dispatcher;
use Amon::Web::Declare;

our @EXPORT = qw/dispatch/;

sub import {
    strict->import;
    warnings->import;
    HTTPx::Dispatcher->export_to_level(1);
    __PACKAGE__->export_to_level(1);
}

sub dispatch {
    my ($class, $c) = @_;
    my $ret = $class->match($c->request);
    if ($ret) {
        my $klass = "@{[ ref Amon->context ]}::C::$ret->{controller}";
        my $action = $ret->{action};
        return $klass->$action($c, $ret->{args});
    } else {
        return res_404();
    }
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher::HTTPxDispatcher;
    connect 'blog/:year/:month' => { controller => 'Blog', action => 'show' };

=head1 SEE ALSO

L<HTTPx::Dispatcher>

