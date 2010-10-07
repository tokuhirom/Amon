package Amon2::Config::Simple;
use strict;
use warnings;
use File::Spec;

sub load {
    my ($class, $c) = (shift, shift);
    my %conf = @_ == 1 ? %{$_[0]} : @_;

    my $env = $conf{environment} || $ENV{PLACK_ENV} || 'development';
    my $fname = File::Spec->catfile($c->base_dir, 'config', "${env}.pl");
    my $config = do $fname or die "Cannot load configuration file: $fname";
    return $config;
}

1;
__END__

=head1 SYNOPSIS

    # do "config/$ENV{PLACK_ENV}.pl"
    use Amon2::Config::Simple;
    sub load_config { Amon2::Config::Simple->load(shift) }

    # do "config/$ENV{RUN_MODE}.pl"
    use Amon2::Config::Simple;
    sub load_config { Amon2::Config::Simple->load(shift, +{ environment => $ENV{RUN_MODE} } ) }

