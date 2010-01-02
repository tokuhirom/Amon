package DeepNamespace::Web::Admin::Dispatcher;
use Amon::Web::Dispatcher;
use feature 'switch';

sub dispatch {
    my ($class, $req) = @_;
    given ($req->path_info) {
        when ('/') {
            return call("Root", 'index');
        }
        default {
            return res_404();
        }
    }
}

1;
