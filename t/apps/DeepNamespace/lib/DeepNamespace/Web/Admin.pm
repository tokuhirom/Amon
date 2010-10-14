package DeepNamespace::Web::Admin;
use parent qw/Amon2::Web/;
__PACKAGE__->setup(
    view_class => 'Text::MicroTemplate::Extended',
    base_name => 'DeepNamespace',
);
1;
