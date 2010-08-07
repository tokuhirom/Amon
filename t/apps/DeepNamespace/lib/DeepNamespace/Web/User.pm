package DeepNamespace::Web::User;
use strict;
use parent qw/DeepNamespace Amon2::Web/;
__PACKAGE__->setup(
    view_class => 'Text::MicroTemplate::Extended',
);
1;
