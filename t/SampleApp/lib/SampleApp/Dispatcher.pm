package SampleApp::Dispatcher;
use Amon::Dispatcher;
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
