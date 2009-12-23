package TTApp::Web::C::Root;
use Amon::Web::C;

sub index {
    render("index.tt", +{ name => 'john' });
}

1;
