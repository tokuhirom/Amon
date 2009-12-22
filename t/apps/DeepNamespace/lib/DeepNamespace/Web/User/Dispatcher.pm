package DeepNamespace::Web::User::Dispatcher;
use Amon::Web::Dispatcher;
use feature 'switch';

sub dispatch {
    my ($class, $req) = @_;
    given ($req->path_info) {
        when ('/') {
            call("Root", 'index');
        }
        default {
            res_404();
        }
    }
}

1;
