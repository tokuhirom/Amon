package Extended::Web::C::Root;
use Amon::Web::C;

sub index {
    render("index.mt");
}

sub die {
    die "OKAY";
}

sub session {
    my $test = c->session->get('test');
    if ($test) {
        my $res = [200, [], ["hello, $test"]];
        c->session->set(test => $test + 1);
        return $res;
    } else {
        c->session->set(test => 1);
        return [200, [], ["first time"]];
    }
}

1;
