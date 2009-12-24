package Amon::Component;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/global_config config model/;
use Amon::Util;

sub global_config { $Amon::_global_config }

sub config {
    my $pkg = caller(0);
    $pkg =~ s/^${Amon::_base}(::)?//;
    return $Amon::_global_config->{$pkg};
}

sub model($) {
    my $name = shift;
    $Amon::_registrar->{"M::$name"} ||= do {
        my $klass = "${Amon::_base}::M::$name";
        Amon::Util::load_class($klass);
        my $conf = global_config->{"M::$name"};
        $klass->new($conf ? $conf : ());
    };
}

1;
__END__

=head1 NAME

Amon::Component - Amon Component Class

=head1 SYNOPSIS

    use Amon::Component;

=head1 DESCRIPTION

=head1 FUNCITIONS

=over 4

=item global_config()

get global configuration

=item config()

Get configuration for caller module.

=item model($model)

get the model class name.

=back

=cut

