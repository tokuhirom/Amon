package Amon::Config::Merger::Simple;
# ABOUT: same stratagy with Sledge::Config.
use strict;
use warnings;

sub merge {
    my ($class, $original, @config) = @_;
    my %res = %$original;
    for my $conf (@config) {
        %res = (%res, %$conf);
    }
    \%res;
}

1;
