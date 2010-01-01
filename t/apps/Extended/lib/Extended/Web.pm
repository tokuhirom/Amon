package Extended::Web;
use strict;
use warnings;
use base qw/Amon::Web/;
__PACKAGE__->base_class('Extended');
__PACKAGE__->request_class('Extended::Web::Request');
1;
