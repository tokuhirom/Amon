package Amon2::Plugin::Web::NoCache;
use strict;
use warnings;

sub init {
    my ($class, $c, $conf) = @_;

    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ($self, $res) = @_;
            $res->header( 'Pragma'        => 'no-cache' );
            $res->header( 'Cache-Control' => 'no-cache' );
        },
    );
}

1;
__END__

=head1 SYNOPSIS

    __PACKAGE__->load_plugins('Web::NoCache');

