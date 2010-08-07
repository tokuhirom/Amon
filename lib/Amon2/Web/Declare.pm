package Amon2::Web::Declare;
use strict;
use warnings;
use base 'Exporter';
use Amon2::Declare;
use Encode ();

our @EXPORT = (qw/res req param param_decoded render render_partial redirect res_404 uri_for args/, @Amon2::Declare::EXPORT);

sub response { Amon2->context->response_class->new(@_) }
sub res      { Amon2->context->response_class->new(@_) }
sub redirect($) { Amon2->context->redirect(@_) }
sub req()    { Amon2->context->request }
sub args()   { Amon2->context->args    }

sub param { req->param(@_) }
sub param_decoded { req->param_decoded(@_) }

sub render         { Amon2->context->render(@_) }
sub render_partial { Amon2->context->render_partial(@_) }
sub uri_for        { Amon2->context->uri_for(@_) }

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

Amon2::Web::Declare - Amon2 web component

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
