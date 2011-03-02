#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Amon2::Setup::Flavor::Basic;

my $flavor_name = "Basic";
GetOptions(
    'help'         => \my $help,
    'flavor=s'     => \$flavor_name,
) or pod2usage(0);
pod2usage(1) if $help;

&main;exit;

sub main {
    my $module = shift @ARGV or pod2usage(0);

    my $flavor_class = $flavor_name =~ s/^\+// ? $flavor_name : "Amon2::Setup::Flavor::$flavor_name";
    eval "use $flavor_class; 1" or die "Cannot load $flavor_class: $@";

    my $flavor = $flavor_class->new(module => $module);
       $flavor->init;
       $flavor->run;
}

__END__

=head1 SYNOPSIS

    % amon-setup.pl MyApp

=head1 AUTHOR

Tokuhiro Matsuno

=cut
