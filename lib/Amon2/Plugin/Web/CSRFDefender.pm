package Amon2::Plugin::Web::CSRFDefender;
use strict;
use warnings;
use String::Random qw/random_regex/;

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

    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ($self, $res) = @_;
            my $token = do {
                if (my $token = $self->session->get('csrf_token')) {
                    $token;
                } else {
                    $token = random_regex('[a-zA-Z0-9_]{32}');
                    $self->session->set('csrf_token' => $token);
                    $token;
                }
            };
            my $html = $res->body;
            if (($res->header('Content-Type') || '') =~ /html/ && not ref $html) {
                $html =~ s!(<form\s*.*?>)!$1\n<input type="hidden" name="csrf_token" value="$token" />!isg;
                $res->body($html);
                $res->header('Content-Length' => length($html));
            }
        },
    );
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
    Amon::Util::add_method($c, 'validate_csrf', \&validate_csrf);
}

sub validate_csrf {
    my $self = shift;

    if ( $self->req->method eq 'POST' ) {
        my $r_token       = $self->req->param('csrf_token');
        my $session_token = $self->session->get('csrf_token');
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0; # good
        }
    }
    return 1; # bad
}

1;
