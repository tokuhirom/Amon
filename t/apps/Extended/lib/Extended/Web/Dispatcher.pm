package Extended::Web::Dispatcher;
use Amon2::Web::Dispatcher;
use feature 'switch';

sub dispatch {
    my ($class, $c) = @_;
    given ($c->request->path_info) {
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
