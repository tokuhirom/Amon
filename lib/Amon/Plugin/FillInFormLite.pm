package Amon::Plugin::FillInFormLite;
use strict;
use warnings;
use Amon::Util;
use HTML::FillInForm::Lite;

sub init {
    my ($class, $c, $conf) = @_;

    Amon::Util::add_method($c->response_class, 'fillin_form', \&_fillin_form);
}

sub _fillin_form {
    my ($self, @stuff) = @_;

    my $html = $self->body();
    my $output = HTML::FillInForm::Lite->fill(\$html, @stuff);
    $self->body($output);
    $self->header('Content-Length' => length($output)) if $self->header('Content-Length');
    return $self;
}

1;
__END__

=head1 NAME

Amon::Plugin::FillInFormLite - HTML::FillInForm::Lite

=head1 SYNOPSIS

  package MyApp::Web;
  use Amon::Web -base => (
  );
  __PACKAGE__->load_plugins(qw/FillInFormLite/);
  1;

  package MyApp::Web::C::Root;

  sub post_edit {
    render('edit.html')->fillin_form(req());
  }

  1;

=head1 DESCRIPTION

HTML::FillInForm::Lite version of L<Amon::Plugin::FillInForm>

=head1 SEE ALSO

L<HTML::FillInForm::Lite>, L<Amon>

=cut

