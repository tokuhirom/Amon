package Amon::V::TT;
use strict;
use warnings;
use File::Spec;
use Template;

sub new {
    my ($class, $conf) = @_;
    my $tt = Template->new(
        ABSOLUTE => 1,
        RELATIVE => 1,
        INCLUDE_PATH => [ File::Spec->catdir(Amon->context->base_dir, 'tmpl'), '.' ],
    );
    bless {tt => $tt}, $class;
}

# entry point
sub render {
    my ($self, $input, $params) = @_;
    $self->{tt}->process($input, $params, \my $output) or die $self->{tt}->error;
    return $output;
}

1;
__END__

=head1 NAME

Amon::V::TT - Amon Template-Toolkit View Class

=head1 SYNOPSIS

    package MyApp::V::TT;
    use Amon::V::TT;
    1;

=head1 DESCRIPTION

=head1 SEE ALSO

L<Template>, L<Amon>

=cut

