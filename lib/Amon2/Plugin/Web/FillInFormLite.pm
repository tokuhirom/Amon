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
    Carp::cluck("\$res->fillin_form() was deprecated. Use \$c->fillin_form(\$stuff) instead.");

    my $html = $self->body();
    my $output = HTML::FillInForm::Lite->fill(\$html, @stuff);
    $self->body($output);
    $self->header('Content-Length' => length($output)) if $self->header('Content-Length');
    return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::FillInFormLite - HTML::FillInForm::Lite

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugins(qw/Web::FillInFormLite/);

    post '/edit' => sub {
        my $c = shift;
        unless (is_valid()) {
            $c->fillin_form($c->req);
            return $c->render('edit.html');
        }
        $c->dbh->update($c->req());
        return $c->redirect('/finished');
    };

=head1 DESCRIPTION

HTML::FillInForm::Lite version of L<Amon2::Plugin::Web::FillInForm>

=head1 SEE ALSO

L<HTML::FillInForm::Lite>, L<Amon2>

=cut

