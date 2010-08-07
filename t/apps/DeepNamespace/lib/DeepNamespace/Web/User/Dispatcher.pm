package DeepNamespace::Web::User::Dispatcher;
use strict;
use feature 'switch';

sub dispatch {
    my ($class, $c) = @_;
    given ($c->request->path_info) {
        when ('/') {
            return DeepNamespace::Web::User::C::Root->index($c);
        }
        default {
            return res_404();
        }
    }
}

1;
