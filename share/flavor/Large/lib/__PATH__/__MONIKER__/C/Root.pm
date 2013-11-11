package <% $module %>::<% $moniker %>::C::Root;
use strict;
use warnings;
use utf8;

sub index {
    my ($class, $c) = @_;

    my $counter = $c->session->get('counter') || 0;
    $counter++;
    $c->session->set('counter' => $counter);
    return $c->render('index.tx', {
        counter => $counter,
    });
}

sub reset_counter {
    my ($class, $c) = @_;

    $c->session->remove('counter');
    return $c->redirect('/');
}

1;
