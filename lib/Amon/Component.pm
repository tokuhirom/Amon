package Amon::Component;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/global_config model/;
use Amon::Util;

sub global_config () { Amon->context->config_class->instance }
sub model ($) { Amon->context->model(@_) }

1;
__END__

=head1 NAME

Amon::Component - Amon Component Class

=head1 SYNOPSIS

    use Amon::Component;

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item global_config()

get global configuration

=item model($model)

get the model class name.

=back

=head1 SEE ALSO

L<Amon>

=cut

