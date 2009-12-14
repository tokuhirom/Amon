package Amon::Component;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/render detach req global_config config redirect res_404/;

=item global_config()

get global configuration

=cut
sub global_config { $Amon::_global_config }

=item config()

Get configuration for caller module.

=cut
sub config {
    my $pkg = caller(0);
    $pkg =~ s/^${Amon::_base}(::)?//;
    return $Amon::_global_config->{$pkg};
}

=item req()

Return request class.

=cut
sub req() { $Amon::_req }

=item param($name)

Get query/body parameter. 

=cut
sub param { $Amon::_req->param(@_) }

=item current_url()

Get current url.

=cut
sub current_url() {
    my $req      = $Amon::_req->request;
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
    my $res = $Amon::_base->view_class->render(@_);
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
    return detach([
        302,
        ['Location' => $location],
        []
    ]);
}

=item detach([$status, $headers, $body])

Detach context and return PSGI response.

=cut
sub detach($) {
    $Amon::_base->call_trigger("BEFORE_DETACH", $_[0]);
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

sub model($) {
    "${Amon::_base}::M::$_[0]"
}

1;
