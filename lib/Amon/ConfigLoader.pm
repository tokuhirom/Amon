package Amon::ConfigLoader;
# EXPERIMENTAL
use strict;
use warnings;
use Amon::Util;
use File::Spec;
use Cwd ();

sub load {
    my $class = shift;
    my $env = $ENV{PLACK_ENV} || 'development';
    my $class_path = $class;
    $class_path =~ s{::}{/}g;
    $class_path .= ".pm";
    my $base = $INC{$class_path};
    $base = Cwd::abs_path($base) || $base;
    $base =~ s{(?:blib/)?lib/$class_path$}{};
    my $fname = File::Spec->catfile($base, 'config', "${env}.pl");
    my $conf = do $fname or die "Cannot load configuration file: $fname";
    return $conf;
}

1;
