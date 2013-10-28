package <% $module %>::<% $moniker %>;
use strict;
use warnings;
use utf8;
use parent qw(<% $module %> Amon2::Web);
use File::Spec;

use Class::Accessor::Lite::Lazy (
    ro_lazy => [qw(session)],
);

# dispatcher
use <% $module %>::<% $moniker %>::Dispatcher;
sub dispatch {
    return (<% $module %>::<% $moniker %>::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# setup view
use <% $module %>::<% $moniker %>::View;
{
    sub create_view {
        my $view = <% $module %>::<% $moniker %>::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *<% $module %>::<% $moniker %>::create_view = sub { $view }; # Class cache.
        $view
    }
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
);

sub show_error {
    my ( $c, $msg, $code ) = @_;
    my $res = $c->render( 'error.tx', { message => $msg } );
    $res->code( $code || 500 );
    return $res;
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
