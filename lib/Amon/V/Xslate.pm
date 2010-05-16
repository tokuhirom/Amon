package Amon::V::Xslate;
use strict;
use warnings;
use base qw/Amon::V::TemplateBase/;
use File::Spec ();
use Scalar::Util ();
use Text::Xslate 0.1015 ();

sub import {
    my $class = shift;
    if (@_>0 && shift eq '-base') {
        my $caller = caller(0);
        no strict 'refs';
        unshift @{"${caller}::ISA"}, $class;
    }
}

sub new {
    my ($class, $c, $conf) = @_;
    $conf->{path} ||= [ File::Spec->catdir($c->base_dir, 'tmpl') ];
    my $xslate = Text::Xslate->new( $conf );
    my $self = bless {context => $c, xslate => $xslate}, $class;
    return $self;
}

sub render {
    my ($self, $input, $params) = @_;
    my $output = $self->{xslate}->render($input, { c => $self->{context}, %{ $params || +{}} });
    return $output;
}

1;
__END__

=head1 NAME

Amon::V::Xslate - Amon Text::Xslate View Class

=head1 SYNOPSIS

    package MyApp::V::Xslate;
    use parent 'Amon::V::Xslate';
    1;

=head1 DESCRIPTION

B<THIS IS EARLY BETA. INTERFACE WILL CHANGE>

This is a wrapper class for L<Text::Xslate>.

=head1 CONFIGURATION

The all configurations for 'V::Xslate' will pass for Text::Xslate->new.

=head1 SEE ALSO

L<Text::Xslate>, L<Amon>

=cut

