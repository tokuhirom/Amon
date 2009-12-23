package Amon::Web::Component;
use strict;
use warnings;
use base 'Exporter';
use Amon::Component;

our @EXPORT = (qw/req param current_url render redirect res_404 detach/, @Amon::Component::EXPORT);

=item req()

Return request class.

=cut
sub req() { $Amon::Web::_req }

=item param($name)

Get query/body parameter.

=cut
sub param { $Amon::Web::_req->param(@_) }

=item current_url()

Get current url.

=cut
sub current_url() {
    my $req      = $Amon::Web::_req->request;
    my $env      = $req->{env};
    my $protocol = 'http';
    my $port     = $env->{SERVER_PORT} || 80;
    my $url      = "http://" . $req->header('Host');
    $url .= "$env->{PATH_INFO}";
    $url .= '?' . $env->{QUERY_STRING};
}

=item render($path, @args)

Render template by L<Text::MicroTemplate>.

=cut
sub render {
    my $view_class = $Amon::Web::_web_base->default_view_class;
    my $view = $Amon::_registrar->{$view_class} ||= do {
        (my $suffix = $view_class) =~ s/^${Amon::_base}:://;
        my $conf = global_config->{$suffix};
        $view_class->new($conf ? $conf : ());
    };
    my $res = $view->render(@_);
    return detach([
        200,
        [
            'Content-Type'   => 'text/html; charset=UTF-8',
            'Content-Length' => length($res)
        ],
        [$res]
    ]);
}

=item redirect($location)

Output redirect response.

=cut
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

=item detach([$status, $headers, $body])

Detach context and return PSGI response.

=cut
sub detach($) {
    $Amon::Web::_web_base->call_trigger("BEFORE_DETACH", $_[0]);
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
