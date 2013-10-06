use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTML::TokeParser';

my %link_tags = (
    a      => 'href',
    area   => 'href',
    frame  => 'src',
    iframe => 'src',
    link   => 'href',
    script => 'src',
);

sub _extract_links {
    my $mech = shift;

    my @links;
    my $parser = HTML::TokeParser->new( \( $mech->content ) );
    while ( my $token = $parser->get_tag( keys %link_tags ) ) {
        push @links, $token->[1]->{ $link_tags{ $token->[0] } };
    }
    return grep { m{^/} } @links;
}

for my $psgi (glob('script/*-server')) {
    subtest $psgi => sub {
        my $app = Plack::Util::load_psgi($psgi);

        my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );
        $mech->credentials( 'admin', 'admin' );
        $mech->get_ok('/');

        my @links = _extract_links($mech);
        for (@links) {
            $mech->get('/');
            $mech->get_ok($_);
        }
    };
}

done_testing();
