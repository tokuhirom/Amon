package Amon2::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;

our @EXPORT_OK = qw/add_method random_string/;

sub add_method {
    my ($klass, $method, $code) = @_;
    no strict 'refs';
    *{"${klass}::${method}"} = $code;
}

sub base_dir($) {
    my $path = shift;
    $path =~ s!::!/!g;
    if (my $libpath = $INC{"$path.pm"}) {
        $libpath =~ s!\\!/!g; # win32
        $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
        File::Spec->rel2abs($libpath || './');
    } else {
        File::Spec->rel2abs('./');
    }
}

sub random_string {
    my $length = shift;
    my @chars = ( 'A'..'Z', 'a'..'z', '0'..'9' );
    my $ret;
    for (1..$length) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
}

1;
__END__

=head1 DESCRIPTION

This is a utility class for Amon2. Do not use this directly.
