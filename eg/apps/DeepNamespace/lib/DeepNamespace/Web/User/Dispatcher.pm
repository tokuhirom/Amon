package DeepNamespace::Web::User::Dispatcher;
use strict;

sub dispatch {
    my ($class, $c) = @_;
    if ($c->request->path_info eq '/') {
        return DeepNamespace::Web::User::C::Root->index($c);
    } else {
        return $c->res_404();
    }
}

1;
