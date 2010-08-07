package Extended::Web;
use Amon2::Web -base => (
    default_view_class => 'MT',
    base_name => 'Extended',
    request_class => 'Extended::Web::Request',
);

__PACKAGE__->load_plugins(
    'HTTPSession' => {
        state => 'Cookie',
        store => 'OnMemory',
    },
);

1;
