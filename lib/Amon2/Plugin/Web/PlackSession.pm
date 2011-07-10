use strict;
use warnings;
use utf8;

package Amon2::Plugin::Web::PlackSession;
use Plack::Session;

sub init {
    my ($class, $context_class, $conf) = @_;

    no strict 'refs';
    *{"${context_class}::session"} = sub {
        Plack::Session->new($_[0]->request->env)
    };
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::PlackSession - Plack::Session integration for Amon2

=head1 SYNOPSIS

    use Amon2::Lite;
    use Plack::Builder;

    get '/' => sub {
        my $c = shift;
        my $cnt = $c->session->get('cnt') || 0;
        $c->session->set( 'cnt', ++$cnt );
        return $c->create_response(
            200,
            [
                'Content-Type'   => 'text/plain',
                'Content-Length' => length($cnt)
            ],
            [$cnt]
        );
    };

    builder {
        enable 'Session';
        MyApp::Web->to_app();
    };

=head1 DESCRIPTION

This module is glue for Amon2 and Plack::Session.

This module provides C<< $c->session >> method. It returns instance of L<Plack::Session>.

=head1 SEE ALSO

L<Plack::Session>

