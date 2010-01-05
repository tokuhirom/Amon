package Amon::Plugin::MobileAgent;
use strict;
use warnings;
use Amon::Util;
use HTTP::MobileAgent;

sub init {
    my ($class, $c, $conf) = @_;
    Amon::Util::add_method(
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

Amon::Plugin::MobileAgent - HTTP::MobileAgent plugin for Amon

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
    __PACKAGE__->load_plugins(
        qw/ MobileAgent /
    );
    1;

=head1 DESCRIPTION

Integrate with L<HTTP::MobileAgent>

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Amon>


=cut

