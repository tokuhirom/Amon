package Amon::Web::Declare;
use strict;
use warnings;
use base 'Exporter';
use Amon::Declare;
use URI::WithBase;

our @EXPORT = (qw/req param render render_partial redirect res_404 detach uri_for/, @Amon::Declare::EXPORT);

sub req() { Amon->context->request }

sub param { req->param(@_) }

sub render {
    my $res = render_partial(@_);
    utf8::encode($res);
    return detach([
        200,
        [
            'Content-Type'   => 'text/html; charset=UTF-8',
            'Content-Length' => length($res)
        ],
        [$res]
    ]);
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
    my $location = shift;
    my $url = req()->base;
    $url =~ s!/+$!!;
    $location =~ s!^/+([^/])!/$1!;
    $url .= $location;
    return detach([
        302,
        ['Location' => $url],
        []
    ]);
}

sub detach($) {
    Amon->context->web_base->call_trigger("BEFORE_DETACH", $_[0]);
    die $_[0];
}

sub res_404 {
    my $text = shift || "404 Not Found";
    detach(
        [
            404,
            ['Content-Length' => length($text)],
            [$text],
        ]
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

=item detach([$status, $headers, $body])

Detach context and return PSGI response.

=back

=cut
