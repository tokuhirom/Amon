package Extended::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index", $c);
}

sub die {
    die "OKAY";
}

sub session {
    my ($class, $c) = @_;

    my $test = $c->session->get('test');
    if ($test) {
        my $res = $c->create_response(200, [], ["hello, $test"]);
        $c->session->set(test => $test + 1);
        return $res;
    } else {
        $c->session->set(test => 1);
        return $c->create_response(200, [], ["first time"]);
    }
}

1;
