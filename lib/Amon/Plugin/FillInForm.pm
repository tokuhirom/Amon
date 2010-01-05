package Amon::Plugin::FillInForm;
use strict;
use warnings;
use Amon::Util;
use HTML::FillInForm;

sub init {
    my ($class, $c, $conf) = @_;

    Amon::Util::add_method($c->response_class, 'fillin_form', \&_fillin_form);
}

sub _fillin_form {
    my ($self, @stuff) = @_;

    my $html = $self->body();
    my $output = HTML::FillInForm->fill(\$html, @stuff);
    $self->body($output);
    return $self;
}

1;
__END__

=head1 NAME

Amon::Plugin::FillInForm - HTML::FillInForm

=head1 SYNOPSIS

  package MyApp::Web;
  use Amon::Web -base => (
  );
  __PACKAGE__->load_plugins(qw/FillInForm/);
  1;

  package MyApp::Web::C::Root;

  sub post_edit {
    render('edit.html')->fillin_form(req());
  }

  1;

=head1 DESCRIPTION

=head1 SEE ALSO

L<HTML::FillInForm>, L<Amon>

=cut

