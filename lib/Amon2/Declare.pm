package Amon2::Declare;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/c/;

*c = *Amon2::context;

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Declare - Amon2 Declare Class

=head1 SYNOPSIS

    use Amon2::Declare;

    c();

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item c()

Get the context object. This is shortcut for C<< Amon2->context() >> method.

=back

=head1 SEE ALSO

L<Amon2>

=cut

