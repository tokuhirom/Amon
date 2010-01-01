package TTApp::Web;
use strict;
use warnings;
use base qw/Amon::Web/;
__PACKAGE__->base_class('TTApp');
__PACKAGE__->default_view_class('TT');
1;
