package Amon::Declare;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/config model db view c logger/;
use Amon::Util;

sub c      ()  { Amon->context            }
sub config ()  { Amon->context->config    }
sub db (;$)    { Amon->context->db(@_)    }
sub model ($)  { Amon->context->model(@_) }
sub view ($)   { Amon->context->view(@_)  }
sub logger ()  { Amon->context->logger()  }

1;
__END__

=head1 NAME

Amon::Declare - Amon Declare Class

=head1 SYNOPSIS

    use Amon::Declare;

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item config()

get configuration from context object.

=item model($model)

get the model class name.

=back

=head1 SEE ALSO

L<Amon>

=cut

