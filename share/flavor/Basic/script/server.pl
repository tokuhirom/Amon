%% cascade "Minimum/script/server.pl"

%% override load_modules -> {
use <% $module %>::Web;
use <% $module %>;
use URI::Escape;
use File::Path ();
%% }

%% override app -> {
my $app = builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__), '..');
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'static');
    enable 'Plack::Middleware::ReverseProxy';

    <% $module %>::Web->to_app();
};
%% }
