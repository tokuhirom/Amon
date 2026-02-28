%% cascade "Minimum/script/server.pl"

%% override load_modules -> {
use <% $module %>::Web;
use <% $module %>;
use URI::Escape;
use File::Path ();
use Plack::Session::Store::File;
%% }

%% override app -> {
my $session_dir = File::Spec->catdir(dirname(__FILE__), '..', 'tmp', 'session');
File::Path::mkpath($session_dir);

my $app = builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__), '..');
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'static');
    enable 'Plack::Middleware::ReverseProxy';
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::File->new(
            dir => $session_dir,
        );

    <% $module %>::Web->to_app();
};
%% }
