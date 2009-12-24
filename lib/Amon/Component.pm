package Amon::Component;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/global_config model/;
use Amon::Util;

sub global_config { $Amon::_global_config ||= $Amon::_base->config_class->instance }

sub model($) {
    my $name = shift;
    my $klass = "${Amon::_base}::M::$name";
    $Amon::_registrar->{$klass} ||= do {
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

=item model($model)

get the model class name.

=back

=head1 SEE ALSO

L<Amon>

=cut

