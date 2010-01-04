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
