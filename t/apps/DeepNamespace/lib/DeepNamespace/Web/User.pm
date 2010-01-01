package DeepNamespace::Web::User;
use strict;
use warnings;
use base qw/Amon::Web/;
__PACKAGE__->base_class('DeepNamespace');
__PACKAGE__->dispatcher_class('Web::User::Dispatcher');
1;
