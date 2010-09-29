package Amon2::Plugin::ConfigLoader;
use strict;
use warnings;
use Amon2::Util;
use File::Spec;
use Cwd ();

sub init {
    my ($class, $c, $conf) = @_;

    my $env = $ENV{PLACK_ENV} || 'development';
    my $fname = File::Spec->catfile($c->base_dir, 'config', "${env}.pl");
    my $config = do $fname or die "Cannot load configuration file: $fname";
    Amon2::Util::add_method($c, 'config', sub { $config });
}

1;
__END__

=head1 NAME

Amon2::ConfigLoader - configuration file loader for Amon2

=head1 SYNOPSIS

    package MyApp;
    use parent qw/Amon2/;
    __PACKAGE__->load_plugins(qw/ConfigLoader/);

=head1 DESCRIPTION

This is configuration file loader for Amon2.

