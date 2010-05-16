package Amon::Declare;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/config model db view c logger/;
use Amon::Util;

sub c      ()  { Amon->context            }
sub config ()  { Amon->context->config    }
sub db (;$)    { Amon->context->db(@_)    }
sub logger ()  { Amon->context->logger()  }

sub view ($)   {
    warn "[DEPRECATED]";
    Amon->context->view(@_)
}

sub model ($)  {
    warn "[DEPRECATED]";
    Amon->context->model(@_);
}

1;
__END__

=head1 NAME

Amon::Declare - Amon Declare Class

=head1 SYNOPSIS

    use Amon::Declare;

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item c()

Get the context object.

=item config()

Get configuration from context object.

=item view($view)

Get the view object.

=item logger()

Get the logger object.

=back

=head1 SEE ALSO

L<Amon>

=cut

