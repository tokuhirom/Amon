package Amon::Sense;
use strict;
use warnings;
use Carp ();
use File::Spec::Functions ();
use Path::Class ();
use Try::Tiny ();

sub import {
    my $pkg = caller(0);

    strict->import;
    warnings->import;

    File::Spec::Functions->export_to_level(1, $pkg, 'catfile');
    Path::Class->export_to_level(1);
    Try::Tiny->export_to_level(1);

    no strict 'refs';
    *{"$pkg\::slurp"} = \&_slurp;
}

# my $content = slurp '<', $fname;
# my $content = slurp $fname;
sub _slurp {
    if (@_ == 1) {
        open(my $fh, '<', $_[0]) or return;
        return do { local $/; <$fh> };
    } else {
        open(my $fh, @_) or return;
        return do { local $/; <$fh> };
    }
}

1;
