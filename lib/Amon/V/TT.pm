package Amon::V::TT;
use strict;
use warnings;
use File::Spec;
use Template;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);
    my $base_class = $args{base_class} || do {
        local $_ = $caller;
        s/::V(?:::.+)?$//;
        $_;
    };
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;
    *{"${caller}::base_class"} = sub { $base_class };
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
        INCLUDE_PATH => [ File::Spec->catdir($self->base_class->base_dir, 'tmpl'), '.' ],
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

