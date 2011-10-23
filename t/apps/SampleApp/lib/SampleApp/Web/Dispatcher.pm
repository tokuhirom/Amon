package SampleApp::Web::Dispatcher;
use Amon2::Web::Dispatcher;

sub dispatch {
    my ($class, $c) = @_;
    if ($c->request->path_info eq '/') {
        return call("Root", 'index');
    } else {
        return res_404();
    }
}

1;
