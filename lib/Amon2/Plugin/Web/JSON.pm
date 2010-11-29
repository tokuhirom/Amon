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
    if ( ( $c->req->user_agent || '' ) =~ /Opera/ ) {
        $res->content_type(
            "application/x-javascript; charset=$encoding");
    }
    else {
        $res->content_type("application/json; charset=$encoding");
    }

    # add UTF-8 BOM if the client is Safari
    if ( ( $c->req->user_agent || '' ) =~ m/Safari/ and $encoding eq 'utf-8' ) {
        $output = "\xEF\xBB\xBF";
    }

    $res->content_length(length($output));
    $res->body($output);

    return $res;
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::Web;
    use base qw/MyApp Amon2::Web/;

    __PACKAGE__->load_plugins(qw/JSON/);

    # in your controller
    return $c->render_json(+{foo => 'bar'}); # return $res

