package Amon::Web::Dispatcher::HTTPxDispatcher;
use strict;
use warnings;
use base qw/Exporter/;
require HTTPx::Dispatcher;
use Amon::Web::Declare;

our @EXPORT = qw/dispatch new/;

sub import {
    HTTPx::Dispatcher->export_to_level(1);
    __PACKAGE__->export_to_level(1);
}

sub new { bless {}, shift }

sub dispatch {
    my ($class, $req) = @_;
    my $ret = $class->match($req);
    if ($ret) {
        my $klass = "@{[ Amon->context->web_base ]}::C::$ret->{controller}";
        my $action = $ret->{action};
        return $klass->$action($ret->{args});
    } else {
        res_404();
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

