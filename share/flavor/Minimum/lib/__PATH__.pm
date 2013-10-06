package <% $module %>;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='4.06';
use 5.008001;

sub load_config {
    +{
        'Text::Xslate' => +{}
    }
}

1;
