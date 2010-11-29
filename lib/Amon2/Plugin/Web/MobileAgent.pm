package Amon2::Plugin::Web::MobileAgent;
use strict;
use warnings;
use Amon2::Util;
use HTTP::MobileAgent;

sub init {
    my ($class, $c, $conf) = @_;
    Amon2::Util::add_method(
        $c,
        'mobile_agent',
        sub {
            $_[0]->{mobile_agent} ||= HTTP::MobileAgent->new($_[0]->req->headers);
        }
    );
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::MobileAgent - HTTP::MobileAgent plugin for Amon2

=head1 SYNOPSIS

    package MyApp::Web;
    use parent qw/MyApp Amon2::Web/;
    __PACKAGE__->load_plugins('Web::MobileAgent');
    1;

    # in your controller
    $c->mobile_agent();

=head1 DESCRIPTION

Integrate with L<HTTP::MobileAgent>

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Amon2>


=cut

