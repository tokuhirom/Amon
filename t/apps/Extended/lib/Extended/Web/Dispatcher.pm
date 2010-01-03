package Extended::Web::Dispatcher;
use Amon::Web::Dispatcher;
use feature 'switch';

sub dispatch {
    my ($class, $req) = @_;
    given ($req->path_info) {
        when ('/') {
            return call("Root", 'index');
        }
        when ('/die') {
            return call("Root", 'die');
        }
        when ('/session') {
            return call("Root", 'session');
        }
        default {
            return res_404();
        }
    }
}

1;
