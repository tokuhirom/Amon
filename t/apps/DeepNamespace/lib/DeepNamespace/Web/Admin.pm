package DeepNamespace::Web::Admin;
use strict;
use warnings;
use base qw/Amon::Web/;
__PACKAGE__->base_class('DeepNamespace');
__PACKAGE__->dispatcher_class('Web::Admin::Dispatcher');
1;
