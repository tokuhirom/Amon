package TTApp;
use strict;
use warnings;
use parent qw/Amon2/;
__PACKAGE__->config(
    {
        'TT' => {
            INCLUDE_PATH => ['tmpl/'],
        },
    },
);
1;
