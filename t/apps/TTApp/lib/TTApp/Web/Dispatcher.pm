package TTApp::Web::Dispatcher;
use strict;
use warnings;
use 5.10.0;

sub dispatch {
    my ($class, $c) = @_;

    given ($c->request->path_info) {
        when ('/') {
            return TTApp::Web::C::Root->index($c);
        }
        default {
            return res_404();
        }
    }
}

1;
