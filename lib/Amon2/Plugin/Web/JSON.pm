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
    unless ($c->can('render_json')) {
        Amon2::Util::add_method($c, 'render_json', \&_render_json);
    }
}

sub _render_json {
    my ($c, $stuff) = @_;

    # for IE7 JSON venularity.
    # see http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html
    my $output = $_JSON->encode($stuff);
    $output =~ s!([+<>])!$_ESCAPE{$1}!g;

    my $user_agent = $c->req->user_agent || '';

    # defense from JSON hijacking
    if ((!$c->request->header('X-Requested-With')) && $user_agent =~ /android/i && defined $c->req->header('Cookie') && ($c->req->method||'GET') eq 'GET') {
        my $res = $c->create_response(403);
        $res->content_type('text/html; charset=utf-8');
        $res->content("Your request may be JSON hijacking.\nIf you are not an attacker, please add 'X-Requested-With' header to each request.");
        $res->content_length(length $res->content);
        return $res;
    }

    my $res = $c->create_response(200);

    my $encoding = $c->encoding();
    $encoding = lc($encoding->mime_name) if ref $encoding;
    $res->content_type("application/json; charset=$encoding");

    # add UTF-8 BOM if the client is Safari
    if ( $user_agent =~ m/Safari/ and $encoding eq 'utf-8' ) {
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

=over 4

=item Browse the JSON files directly.

This module escapes '<', '>', and '+' characters by "\uXXXX" form. Browser don't detects the JSON as HTML.

And also this module outputs "X-Content-Type-Options: nosniff" header for IEs.

It's good enough, I hope.

=item JSON Hijacking

Latest browsers doesn't have a JSON hijacking issue(I hope). __defineSetter__ or UTF-7 attack was resolved by browsers.

But Firefox<=3.0.x and Android phones have issue on Array constructor, see L<http://d.hatena.ne.jp/ockeghem/20110907/p1>.

Firefox<=3.0.x was outdated. Web application developers doesn't need to add workaround for it, see L<http://en.wikipedia.org/wiki/Firefox#Version_release_table>.

L<Amon2::Plugin::Web::JSON> have a JSON hijacking detection feature. Amon2::Plugin::Web::JSON returns "403 Forbidden" response if following pattern request.

=over 4

=item The request have 'Cookie' header.

=item The request doesn't have 'X-Requested-With' header.

=item The request contains /android/i string in 'User-Agent' header.

=item Request method is 'GET'

=back

=back

See also the L<hasegawayosuke's article(Japanese)|http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html>.

=head1 THANKS TO

hasegawayosuke

