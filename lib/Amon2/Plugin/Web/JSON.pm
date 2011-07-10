package Amon2::Plugin::Web::JSON;
use strict;
use warnings;
use JSON 2 qw/encode_json/;
use Amon2::Util ();

my $_JSON = JSON->new()->ascii(1);

my %_ESCAPE = (
    '+' => '\\u002b', # do not eval as UTF-7
    '<' => '\\u003c', # do not eval as HTML
    '>' => '\\u003e', # ditto.
);

sub init {
    my ($class, $c, $conf) = @_;
    Amon2::Util::add_method($c, 'render_json', \&_render_json);
}

sub _render_json {
    my ($c, $stuff) = @_;

    # for IE7 JSON venularity.
    # see http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html
    my $output = $_JSON->encode($stuff);
    $output =~ s!([+<>])!$_ESCAPE{$1}!g;

    my $res = $c->create_response(200);

    my $encoding = $c->encoding();
    $encoding = lc($encoding->mime_name) if ref $encoding;
    # chrome bug
    if ( ( $c->req->user_agent || '' ) =~ /Chrome/ and
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

    $res->header( 'X-Content-Type-Options' => 'nosniff' ); # defense from XSS
    $res->content_length(length($output));
    $res->body($output);

    return $res;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::JSON - JSON plugin

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugins(qw/Web::JSON/);

    get '/' => sub {
        my $c = shift;
        return $c->render_json(+{foo => 'bar'});
    };

    __PACKAGE__->to_app();

=head1 DESCRIPTION

This is a JSON plugin.

=head1 METHODS

=over 4

=item $c->render_json(\%dat);

Generate JSON data from C<< \%dat >> and returns instance of L<Plack::Response>.

=back

=head1 FAQ

=over 4

=item How can I use JSONP?

You can use JSONP by using L<Plack::Middleware::JSONP>.

=back

=head1 JSON and security

See the L<hasegawayosuke's article(Japanese)|http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html>.

=head1 THANKS TO

hasegawayosuke

