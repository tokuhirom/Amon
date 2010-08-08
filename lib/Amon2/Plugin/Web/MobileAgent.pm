package Amon2::Plugin::Web::MobileAgent;
use strict;
use warnings;
use Amon2::Util;
use HTTP::MobileAgent;

sub init {
    my ($class, $c, $conf) = @_;
    Amon2::Util::add_method(
        $c->request_class,
        'mobile_agent',
        sub {
            $_[0]->{mobile_agent} ||= HTTP::MobileAgent->new($_[0]->headers);
        }
    );
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::MobileAgent - HTTP::MobileAgent plugin for Amon2

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web -base => (
        view_class => 'Text::MicroTemplate::File',
    );
    __PACKAGE__->load_plugins(
        qw/ Web::MobileAgent /
    );
    1;

    # in your controller
    $c->request->mobile_agent();

=head1 DESCRIPTION

Integrate with L<HTTP::MobileAgent>

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Amon2>


=cut

