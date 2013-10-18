package Amon2::Plugin::Web::XSRFProtection;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Amon2::Util ();

use constant {
    TOKEN_KEY => 'Amon2::Plugin::Web::XSRFProtection::token_key',
};

sub init {
    my ($class, $c, $conf) = @_;

    $conf = +{
        enable_html_filter => 1,
        enable_auto_check  => sub { 1 },
        param_name         => 'xsrf_token',
        header_name        => 'X-XSRF-TOKEN',
        cookie_httponly    => 1,
        cookie_name        => 'XSRF-TOKEN',
        cookie_secure      => 0,
        %{$conf||{}}
    };

    # Set HTML filter
    if ($conf->{enable_html_filter}) {
        $c->add_trigger(
            HTML_FILTER => sub {
                my ($self, $html) = @_;
                $html =~ s!(<form\s*.*?\s*method=['"]?post['"]?\s*.*?>)!qq{$1\n<input type="hidden" name="}.$conf->{param_name}.qq{" value="}.$self->xsrf_token().qq{" />}!geis;
                return $html;
            },
        );
    }

    # Automatic XSRF token valdiation.
    if ($conf->{enable_auto_check}) {
        $c->add_trigger(
            BEFORE_DISPATCH => sub {
                my $self = shift;
                if ($conf->{enable_auto_check}->($c) && not $self->validate_xsrf_token()) {
                    return $self->create_simple_status_page(
                        403, 'XSRF token validation failed.'
                    );
                } else {
                    return;
                }
            }
        );
    }

    # Inject XSRF token to the cookie.
    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ($self, $res) = @_;
            $res->cookies->{$conf->{cookie_name}} = +{
                value    => $self->xsrf_token,
                httponly => $conf->{cookie_httponly},
            };
        }
    );

    # Add a method to get XSRF token
    Amon2::Util::add_method($c, 'xsrf_token', sub {
        my $self = shift;

        return $self->{TOKEN_KEY()} ||= do {
            if (my $token = $self->req->cookies->{$conf->{cookie_name}}) {
                $token;
            } else {
                Amon2::Util::random_string(32);
            }
        };
    });

    # Add a method to validate XSRF token
    Amon2::Util::add_method($c, 'validate_xsrf_token', sub {
        my $self = shift;

        my $request_method = $self->req->method;
        unless ( $request_method eq 'GET' || $request_method eq 'HEAD' ) {
            my $r_token       = $self->req->param($conf->{param_name}) || $self->req->header($conf->{header_name});
            my $session_token = $self->xsrf_token();
            if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
                return 0; # bad
            }
        }
        return 1; # good
    });
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::XSRFProtection - (EXPERIMENTAL) XSRF Protector

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::XSRFProtection');

=head1 DESCRIPTION

This plugin denies XSRF request.

This plugin is the a successor to Amon2::Plugin::Web::CSRFDefender.

=head1 1 and 2

=head2 What's different?

Most of important thing is "XSRFProtection" does not use session store.

It handles cookie directly.

=head2 Compatibility

Methods are same. Configuration variable and default value is different.

=head2 AngularJS friendly

Default key names are AngularJS compatible.

=head1 CONFIGURATION VARIABLE

=over 4

=item enable_html_filter: Bool

Default: C< 1 >

This flag enables HTML rewriting filter. If you disabled 

=item enable_auto_check: CodeRef|Undef

Default: C<sub { 1 }>

XSRFProtection calls this callback function with C<< $c >>. If you want to disable XSRF detection for specific path, you can customize this callback function.

    __PACKAGE__->load_plugin(
        'Web::XSRFProtection' => {
            enable_auto_check => sub {
                my $c = shift;
                $c->add_trigger()
            }
        }
    );


If you set this flag as undefined value, XSRFProtection don't checks XSRF token automatically.
(In this case, you need to check XSRF attack by calling C<< $c->validate_xsrf_token() >> in your code.)

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

=item $c->xsrf_token()

Get a XSRF token. This method is useful to add token for AJAX request.

=item $c->validate_xsrf_token()

You can validate XSRF token manually.

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Amon2>, L<http://docs.angularjs.org/api/ng.$http>
