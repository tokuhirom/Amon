package Amon::Web::Component;
use strict;
use warnings;
use base 'Exporter';
use Amon::Component;
use URI::WithBase;

our @EXPORT = (qw/req param current_url render redirect res_404 detach uri_for/, @Amon::Component::EXPORT);

sub req() { Amon->context->request }

sub param { req->param(@_) }

sub current_url() {
    my $req      = req;
    my $env      = $req->{env};
    my $protocol = 'http';
    my $port     = $env->{SERVER_PORT} || 80;
    my $url      = "http://" . $req->header('Host');
    $url .= $env->{PATH_INFO};
    $url .= '?' . $env->{QUERY_STRING} if $env->{QUERY_STRING};
}

sub render {
    my $c = Amon->context;
    my $view_class = $c->web_base->default_view_class;
    my $view = ($c->{_components}->{view_class} ||= do {
        (my $suffix = $view_class) =~ s/^@{[ ref $c ]}:://;
        my $conf = $c->config->{suffix};
        $view_class->new($conf ? $conf : ());
    });
    my $res = $view->render(@_);
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

Amon::Web::Component - Amon web component

=head1 FUNCTIONS

=over 4

=item req()

Return request class.

=item param($name)

Get query/body parameter.

=item current_url()

Get current URL.

=item render($path, @args)

Render template by L<Text::MicroTemplate>.

=item redirect($location)

Output redirect response.

=item detach([$status, $headers, $body])

Detach context and return PSGI response.

=back

=cut
