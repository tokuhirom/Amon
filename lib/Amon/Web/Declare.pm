package Amon::Web::Declare;
use strict;
use warnings;
use base 'Exporter';
use Amon::Declare;
use Encode ();

our @EXPORT = (qw/res req param param_decoded render render_partial redirect res_404 uri_for args/, @Amon::Declare::EXPORT);

sub response { Amon->context->response_class->new(@_) }
sub res      { Amon->context->response_class->new(@_) }
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

sub uri_for {
    my ($path, $query) = @_;
    my $root = req->{env}->{SCRIPT_NAME} || '/';
    $root =~ s{([^/])$}{$1/};
    $path =~ s{^/}{};

    my @q;
    while (my ($key, $val) = each %$query) {
        $val = join '', map { /^[a-zA-Z0-9_.!~*'()-]$/ ? $_ : '%' . uc(unpack('H2', $_)) } split //, $val;
        push @q, "${key}=${val}";
    }
    $root . $path . (scalar @q ? '?' . join('&', @q) : '');
}

sub redirect($) {
    my $c = Amon->context;
    my $location = shift;
    my $url = do {
        if ($location =~ m{^https?://}) {
            $location;
        } else {
            my $url = $c->request->base;
            $url =~ s!/+$!!;
            $location =~ s!^/+([^/])!/$1!;
            $url .= $location;
        }
    };
    response(
        302,
        ['Location' => $url],
        []
    );
}

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
