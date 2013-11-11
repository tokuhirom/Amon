package Amon2::Plugin::Web::CSRFDefender;
use strict;
use warnings;
use Amon2::Util ();

our $ERROR_HTML = <<'...';
<!doctype html>
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>
      Session validation failed.
    </p>
  </body>
</html>
...

sub init {
    my ($class, $c, $conf) = @_;

    my $form_regexp = $conf->{post_only} ? qr{<form\s*.*?\s*method=['"]?post['"]?\s*.*?>}is : qr{<form\s*.*?>}is;

    unless ($conf->{no_html_filter}) {
        $c->add_trigger(
            HTML_FILTER => sub {
                my ($self, $html) = @_;
                $html =~ s!($form_regexp)!qq{$1\n<input type="hidden" name="csrf_token" value="}.$self->get_csrf_defender_token().qq{" />}!ge;
                return $html;
            },
        );
    }
    unless ($conf->{no_validate_hook}) {
        $c->add_trigger(
            BEFORE_DISPATCH => sub {
                my $self = shift;
                if (not $self->validate_csrf()) {
                    return $self->create_response(
                        403,
                        [
                            'Content-Type'   => 'text/html',
                            'Content-Length' => length($ERROR_HTML)
                        ],
                        $ERROR_HTML
                    );
                } else {
                    return;
                }
            }
        );
    }
    Amon2::Util::add_method($c, 'get_csrf_defender_token', \&get_csrf_defender_token);
    Amon2::Util::add_method($c, 'validate_csrf', \&validate_csrf);
}

sub get_csrf_defender_token {
    my $self = shift;

    if (my $token = $self->session->get('csrf_token')) {
        $token;
    } else {
        $token = Amon2::Util::random_string(32);
        $self->session->set('csrf_token' => $token);
        $token;
    }
}

sub validate_csrf {
    my $self = shift;

    if ( $self->req->method eq 'POST' ) {
        my $r_token       = $self->req->param('csrf_token') || $self->req->header('x-csrf-token');
        my $session_token = $self->session->get('csrf_token');
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0; # bad
        }
    }
    return 1; # good
}

1;
__END__

=for stopwords CSRFDefender

=head1 NAME

Amon2::Plugin::Web::CSRFDefender - Anti CSRF filter

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::CSRFDefender');

=head1 DESCRIPTION

This plugin denies CSRF request.

Do not use this with L<HTTP::Session2>. Because L<HTTP::Session2> has XSRF token management function by itself.

=head1 WARNINGS

This module will split from Amon2 core distribution. You need to list this module in your cpanfile.

=head1 METHODS

=over 4

=item $c->get_csrf_defender_token()

Get a CSRF defender token. This method is useful to add token for AJAX request.

=item $c->validate_csrf()

You can validate CSRF token manually.

=back

=head1 PARAMETERS

=over 4

=item no_validate_hook

Do not run validation automatically.

=item no_html_filter

Disable HTML rewriting filter. By default, CSRFDefender inserts XSRF token for each form element.

It's very useful but it hits performance issue if your site is very high traffic.

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Amon2>

