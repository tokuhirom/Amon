package Extended::Web;
use Amon::Web (
    default_view_class => 'Extended::V::MT',
    base_class => 'Extended',
    request_class => 'Extended::Web::Request',
);
1;
