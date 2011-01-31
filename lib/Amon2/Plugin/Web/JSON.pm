package Amon2::Plugin::Web::JSON;
use strict;
use warnings;
use JSON qw/encode_json/;
use Amon2::Util ();

sub init {
    my ($class, $c, $conf) = @_;
    Amon2::Util::add_method($c, 'render_json', \&_render_json);
}

sub _render_json {
    my ($c, $stuff) = @_;

    my $output = encode_json($stuff);

    my $res = $c->create_response(200);

    my $encoding = $c->encoding();
    $encoding = lc($encoding->mime_name) if ref $encoding;
    if ( ( $c->req->user_agent || '' ) =~ /Opera/ ) {
        $res->content_type(
            "application/x-javascript; charset=$encoding");
    }
    # chrome bug
    elsif ( ( $c->req->user_agent || '' ) =~ /Chrome/ and
        ( $c->req->env->{'HTTP_X_REQUESTED_WITH'} || '' ) ne 'XMLHttpRequest' ) {
        $res->content_type("text/html; charset=$encoding");
    }
    else {
        $res->content_type("application/json; charset=$encoding");
    }

    # add UTF-8 BOM if the client is Safari
    if ( ( $c->req->user_agent || '' ) =~ m/Safari/ and $encoding eq 'utf-8' ) {
        $output = "\xEF\xBB\xBF" . $output;
    }

    $res->content_length(length($output));
    $res->body($output);

    return $res;
}

1;
__END__

=encoding utf-8

=head1 SYNOPSIS

    package MyApp::Web;
    use base qw/MyApp Amon2::Web/;

    __PACKAGE__->load_plugins(qw/JSON/);

    # in your controller
    return $c->render_json(+{foo => 'bar'}); # return $res

