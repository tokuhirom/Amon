package Extended::Web;
use Amon::Web -base => (
    default_view_class => 'MT',
    base_class => 'Extended',
    request_class => 'Extended::Web::Request',
);
1;
