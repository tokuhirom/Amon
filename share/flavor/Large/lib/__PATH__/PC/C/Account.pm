package <% $module %>::PC::C::Account;
use strict;
use warnings;
use utf8;

sub logout {
    my ($class, $c) = @_;
    $c->session->expire();
    $c->redirect('/');
}

1;
