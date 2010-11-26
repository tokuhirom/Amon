package Amon2::Plugin::Web::FillInFormLite;
use strict;
use warnings;
use Amon2::Util;
use HTML::FillInForm::Lite;

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
            return HTML::FillInForm::Lite->fill(\$html, @stuff);
        },
    );
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

Amon2::Plugin::Web::FillInFormLite - HTML::FillInForm::Lite

=head1 SYNOPSIS

  package MyApp;
  use parent qw/Amon2/;

  package MyApp::Web;
  use parent qw/MyApp Amon2::Web;
  __PACKAGE__->load_plugins(qw/Web::FillInFormLite/);
  1;

  package MyApp::Web::C::Root;

  sub post_edit {
    my $c = shift;
    $c->fillin_form($c->req());
    $c->render('edit.html');
  }

  1;

=head1 DESCRIPTION

HTML::FillInForm::Lite version of L<Amon2::Plugin::FillInForm>

=head1 SEE ALSO

L<HTML::FillInForm::Lite>, L<Amon2>

=cut

