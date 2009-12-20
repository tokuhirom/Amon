package Amon::Component;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/global_config config model/;
use UNIVERSAL::require;

=item global_config()

get global configuration

=cut
sub global_config { $Amon::_global_config }

=item config()

Get configuration for caller module.

=cut
sub config {
    my $pkg = caller(0);
    $pkg =~ s/^${Amon::_base}(::)?//;
    return $Amon::_global_config->{$pkg};
}

=item model($model)

get the model class name.

=cut
sub model($) {
    my $name = shift;
    $Amon::_registrar->{"M::$name"} ||= do {
        my $klass = "${Amon::_base}::M::$name";
        $klass->use or die $@;
        my $conf = global_config->{"M::$name"};
        $klass->new($conf ? $conf : ());
    };
}

1;
