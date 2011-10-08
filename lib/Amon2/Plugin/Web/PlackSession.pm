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

Amon2::Plugin::Web::PlackSession - (DEPRECATED)

=head1 DESCRIPTION

This module was deprecated.

Amon2 3.00+ provides C<< $c->session >> natively.

=head1 SEE ALSO

L<Plack::Session>

