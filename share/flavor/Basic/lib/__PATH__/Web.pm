package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

use Class::Accessor::Lite::Lazy (
    ro_lazy => [qw(session)],
);

# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return (<% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::JSON',
);


# setup view
use <% $module %>::Web::View;
{
    sub create_view {
        my $view = <% $module %>::Web::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *<% $module %>::Web::create_view = sub { $view }; # Class cache.
        $view
    }
}

use HTTP::Session2::ClientStore;
# Amon2 authors recommend to use HTTP::Session2::ServerStore, if you can do it.
sub _build_session {
    my $c = shift;

    HTTP::Session2::ClientStore->new(
        env  => $c->req->env(),
        salt => <: random_string() :>
    );
}

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;

        # Validate XSRF token
        if ($c->req->method ne 'GET' && $c->req->method ne 'HEAD') {
            my $xsrf_token = $c->req->header('X-XSRF-TOKEN') || $c->req->param('XSRF-TOKEN');
            unless ($c->session->validate_xsrf_token($xsrf_token)) {
                return $c->create_simple_status_page(
                    403,
                    'Missing XSRF token'
                );
            }
        }

        return;
    },
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );

        # Finalize session if session object was loaded.
        if ($c->{session}) {
            $c->{session}->finalize_plack_response($res);
        }
    },
);

1;
