package Extended;
use strict;
use warnings;
use parent qw/Amon2/;
use Extended::V::MT::Context;

sub load_config {
    +{
        'Log::Dispatch'                 => +{},
        'Text::MicroTemplate::Extended' => {
            include_path => './tmpl/',
            package_name => 'Extended::V::MT::Context',
        }
    };
}

__PACKAGE__->load_plugin('LogDispatch');

1;
