package Amon2::Plugin::Web::CSRFDefender2;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Amon2::Util ();

use constant {
    TOKEN_KEY => 'Amon2::Plugin::Web::CSRFDefender2::token_key',
};

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

    $conf = +{
        enable_html_filter => 1,
        enable_auto_check  => sub { 1 },
        cookie_httponly    => 1,
        cookie_name        => 'csrf_token',
        cookie_secure      => 0,
        %{$conf||{}}
    };

    # Set HTML filter
    if ($conf->{enable_html_filter}) {
        $c->add_trigger(
            HTML_FILTER => sub {
                my ($self, $html) = @_;
                $html =~ s!(<form\s*.*?\s*method=['"]?post['"]?\s*.*?>)!qq{$1\n<input type="hidden" name="csrf_token" value="}.$self->get_csrf_defender_token().qq{" />}!geis;
                return $html;
            },
        );
    }

    # Automatic CSRF token valdiation.
    if ($conf->{enable_auto_check}) {
        $c->add_trigger(
            BEFORE_DISPATCH => sub {
                my $self = shift;
                if ($conf->{enable_auto_check}->($c) && not $self->validate_csrf()) {
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

    # Inject csrf token to the cookie.
    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ($self, $res) = @_;
            $res->cookies->{$conf->{cookie_name}} = +{
                value    => $self->get_csrf_defender_token,
                httponly => $conf->{cookie_httponly},
            };
        }
    );

    # Add a method to get CSRF token
    Amon2::Util::add_method($c, 'get_csrf_defender_token', \&get_csrf_defender_token);

    # Add a method to validate CSRF token
    Amon2::Util::add_method($c, 'validate_csrf', \&validate_csrf);
}

sub get_csrf_defender_token {
    my $self = shift;

    return $self->{TOKEN_KEY()} ||= do {
        if (my $token = $self->req->cookies->{'csrf_token'}) {
            $token;
        } else {
            Amon2::Util::random_string(32);
        }
    };
}

sub validate_csrf {
    my $self = shift;

    my $request_method = $self->req->method;
    unless ( $request_method eq 'GET' || $request_method eq 'HEAD' ) {
        my $r_token       = $self->req->param('csrf_token');
        my $session_token = $self->get_csrf_defender_token();
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0; # bad
        }
    }
    return 1; # good
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::CSRFDefender2 - (EXPERIMENTAL) CSRF Defender

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::CSRFDefender2');

=head1 DESCRIPTION

This plugin denies CSRF request.

This plugin is the a successor to Amon2::Plugin::Web::CSRFDefender.

=head1 1 and 2

=head2 What's different?

Most of important thing is "CSRFDefender2" does not use session store.

It handles cookie directly.

=head2 Compatibility

Methods are same. Configuration variable and default value is different.

=head1 CONFIGURATION VARIABLE

=over 4

=item enable_html_filter: Bool

Default: C< 1 >

This flag enables HTML rewriting filter. If you disabled 

=item enable_auto_check: CodeRef|Undef

Default: C<sub { 1 }>

CSRFDefender2 calls this callback function with C<< $c >>. If you want to disable CSRF detection for specific path, you can customize this callback function.

    __PACKAGE__->load_plugin(
        'Web::CSRFDefender2' => {
            enable_auto_check => sub {
                my $c = shift;
                $c->add_trigger()
            }
        }
    );


If you set this flag as undefined value, CSRFDefender2 don't checks CSRF token automatically.
(In this case, you need to check CSRF attack by calling C<< $c->validate_csrf() >> in your code.)

=item cookie_httponly: Bool

Default: C< 1 >

This specifies httponly flag. I don't suggest to disable this value.

=item cookie_name: Str

Default: C<'csrf_token'>

You can customize the cookie name.

=item cookie_secure: Bool

Default: C< 0 >

You can add the 'secure' flag for the cookie.

=back

=head1 METHODS

=over 4

=item $c->get_csrf_defender_token()

Get a CSRF defender token. This method is useful to add token for AJAX request.

=item $c->validate_csrf()

You can validate CSRF token manually.

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Amon2>
