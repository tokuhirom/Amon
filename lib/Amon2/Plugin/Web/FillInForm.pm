package Amon2::Plugin::Web::FillInForm;
use strict;
use warnings;
use Amon2::Util;
use HTML::FillInForm;

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method(ref $c || $c, 'fillin_form', \&_fillin_form2);
    Amon2::Util::add_method(ref $c->create_response(), 'fillin_form', \&_fillin_form);
}

sub _fillin_form2 {
    my ($self, @stuff) = @_;
    $self->add_trigger(
        'HTML_FILTER' => sub {
            my ($c, $html) = @_;
            return HTML::FillInForm->fill(\$html, @stuff);
        },
    );
}

sub _fillin_form {
    my ($self, @stuff) = @_;

    Carp::carp("\$res->fillin_form() was deprecated. Use \$c->fillin_form(\$stuff) instead.");

    my $html = $self->body();
    my $output = HTML::FillInForm->fill(\$html, @stuff);
    $self->body($output);
    $self->header('Content-Length' => length($output)) if $self->header('Content-Length');
    return $self;
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::FillInForm - HTML::FillInForm

=head1 SYNOPSIS

  package MyApp::Web;
  use parent qw/MyApp Amon2::Web/;
  __PACKAGE__->load_plugins(qw/Web::FillInForm/);
  1;

  package MyApp::Web::C::Root;

  sub post_edit {
    my $c = shift;
    $c->fillin_form($c->req());
    $c->render('edit.html');
  }

  1;

=head1 DESCRIPTION

HTML::FillInForm integration for Amon2.

=head1 SEE ALSO

L<HTML::FillInForm>, L<Amon2>

=cut

