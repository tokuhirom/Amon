package Amon::V::TT;
use strict;
use warnings;
use base qw/Amon::V::TemplateBase/;
use File::Spec;
use Template;
use Amon::Mixin::Context;

sub import {
    my $class = shift;
    if (@_>0 && shift eq '-base') {
        my $caller = caller(0);
        no strict 'refs';
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub new {
    my ($class, $conf) = @_;
    bless {}, $class;
}

# entry point
sub render {
    my ($self, $input, $params) = @_;
    my $tt = Template->new(
        ABSOLUTE => 1,
        RELATIVE => 1,
        INCLUDE_PATH => [ File::Spec->catdir($self->context->base_dir, 'tmpl'), '.' ],
    );
    $tt->process($input, $params, \my $output) or die $tt->error;
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

