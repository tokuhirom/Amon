package Amon2::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;

our @EXPORT_OK = qw/add_method/;

sub add_method {
    my ($klass, $method, $code) = @_;
    no strict 'refs';
    *{"${klass}::${method}"} = $code;
}

sub base_dir($) {
    my $path = shift;
    $path =~ s!::!/!g;
    if (my $libpath = $INC{"$path.pm"}) {
        $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
        File::Spec->rel2abs($libpath || './');
    } else {
        File::Spec->rel2abs('./');
    }
}

1;
__END__

=head1 NAME

Amon2::Util - Amon2 Utility Class

=head1 DESCRIPTION

This is a utility functions for L<Amon2>.

=head1 FUNCTIONS


=head1 SEE ALSO

L<Catalyst::Utils>, L<Plack::Util>

=cut

