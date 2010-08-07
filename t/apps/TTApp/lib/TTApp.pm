package TTApp;
use Amon2 -base;
__PACKAGE__->config(
    {
        'Tfall::TT' => {
            INCLUDE_PATH => ['tmpl/'],
        },
    },
);
1;
