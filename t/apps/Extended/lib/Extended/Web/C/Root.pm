package Extended::Web::C::Root;
use strict;
use warnings;
use Amon2::Web::Declare;

sub index {
    render("index.mt");
}

sub die {
    die "OKAY";
}

sub session {
    my $test = c->session->get('test');
    if ($test) {
        my $res = res(200, [], ["hello, $test"]);
        c->session->set(test => $test + 1);
        return $res;
    } else {
        c->session->set(test => 1);
        return res(200, [], ["first time"]);
    }
}

1;
