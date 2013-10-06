use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use <% $module %>::Web;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static');
    <% $module %>::Web->to_app();
};
