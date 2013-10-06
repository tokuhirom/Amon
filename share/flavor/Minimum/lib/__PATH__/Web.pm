package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw(<% $module %> Amon2::Web);
use File::Spec;

sub dispatch {
    my ($c) = @_;

    $c->render('index.tx');
}

# setup view
use <% $module %>::Web::View;
{
    my $view = <% $module %>::Web::View->make_instance(__PACKAGE__);
    sub create_view { $view }
}

__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        # for your security
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
        $res->header( 'X-Frame-Options' => 'DENY' );
    },
);

1;
