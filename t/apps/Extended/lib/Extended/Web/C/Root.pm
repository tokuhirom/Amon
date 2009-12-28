package Extended::Web::C::Root;
use Amon::Web::C;

sub index {
    render("index.mt");
}

sub die {
    die "OKAY";
}

1;
