package TTApp::Web;
use parent qw/TTApp Amon2::Web/;
__PACKAGE__->setup(
    view_class => 'TT',
);
1;
