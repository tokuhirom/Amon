package Amon::Web::Declare;
use strict;
use warnings;
use base 'Exporter';
use Amon::Declare;
use Encode ();

our @EXPORT = (qw/res req param param_decoded render render_partial redirect res_404 uri_for args/, @Amon::Declare::EXPORT);

sub response { Amon->context->response_class->new(@_) }
sub res      { Amon->context->response_class->new(@_) }
sub redirect($) { Amon->context->redirect(@_) }
sub req()    { Amon->context->request }
sub args()   { Amon->context->args    }

sub param { req->param(@_) }
sub param_decoded { req->param_decoded(@_) }

sub render {
    return Amon->context->view()->make_response(@_);
}

sub render_partial {
    return Amon->context->view()->render(@_);
}

sub uri_for { Amon->context->uri_for(@_) }

sub res_404 {
    my $text = shift || "404 Not Found";
    response(
        404,
        ['Content-Length' => length($text)],
        [$text],
    );
}

1;
__END__

=head1 name

Amon::Web::Declare - Amon web component

=head1 FUNCTIONS

=over 4

=item req()

Return request class.

=item param($name)

Get query/body parameter.

=item render($path, @args)

Render template by L<Text::MicroTemplate>.

=item redirect($location)

Output redirect response.

=back

=cut
