package <% $package // ($module ~ "::Web::Plugin::Session") %>;
use strict;
use warnings;
use utf8;

use Amon2::Util;

sub init {
    my ($class, $c) = @_;

    Amon2::Util::add_method($c, 'xsrf_token', \&_xsrf_token);
    Amon2::Util::add_method($c, 'validate_xsrf_token', \&_validate_xsrf_token);

    # Ensure and validate XSRF token.
    $c->add_trigger(
        BEFORE_DISPATCH => sub {
            my ( $c ) = @_;
            _xsrf_token($c); # initialize on first request

            if ($c->req->method ne 'GET' && $c->req->method ne 'HEAD') {
                my $token = $c->req->header('X-XSRF-TOKEN')
                         || $c->req->param('XSRF-TOKEN');
                unless (_validate_xsrf_token($c, $token)) {
                    return $c->create_simple_status_page(
                        403, 'XSRF detected.'
                    );
                }
            }
            return;
        },
    );

    # Expose XSRF token as a readable cookie for JavaScript helper.
    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ( $c, $res ) = @_;
            return unless $res->can('cookies');
            my $token = _xsrf_token($c);
            $res->cookies->{'XSRF-TOKEN'} = {
                value    => $token,
                path     => '/',
                httponly => 0,
            };
            return;
        },
    );
}

sub _xsrf_token {
    my $self = shift;
    my $token = $self->session->get('xsrf_token');

    if (!defined $token || $token eq '') {
        $token = Amon2::Util::random_string(32);
        $self->session->set('xsrf_token' => $token);
    }

    return $token;
}

sub _validate_xsrf_token {
    my ($self, $token) = @_;
    return unless defined $token;

    my $session_token = _xsrf_token($self);
    return defined $session_token && $token eq $session_token;
}

1;
__END__

=head1 DESCRIPTION

This module manages session for <% $module %>.
