package Extended::Web;
use Amon2::Web -base => (
    view_class => 'Text::MicroTemplate::File',
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
