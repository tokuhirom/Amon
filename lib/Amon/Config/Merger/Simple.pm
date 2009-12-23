package Amon::Config::Merger::Simple;
# ABOUT: same stratagy with Sledge::Config.
use strict;
use warnings;

sub merge {
    my ($class, $original, @config) = @_;
    my %res = %$original;
    for my $conf (@config) {
        while (my ($k, $v) = each %$conf) {
            $res{$k} = $v unless exists $res{$k};
        }
    }
    \%res;
}

1;
