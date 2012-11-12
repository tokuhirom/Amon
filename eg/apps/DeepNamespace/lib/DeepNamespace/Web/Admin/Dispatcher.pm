package DeepNamespace::Web::Admin::Dispatcher;
use strict;

sub dispatch {
    my ($class, $c) = @_;
    if ($c->request->path_info eq '/') {
        return DeepNamespace::Web::Admin::C::Root->index($c);
    } else {
        return $c->res_404();
    }
}

1;
