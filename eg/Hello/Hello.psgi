use Hello::Web;
use Plack::Builder;
use File::Spec;
use File::Basename;

my $config = do File::Spec->catfile(dirname(__FILE__), 'config.pl') or die "cannot load configuration file";

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => './htdocs/';
    Hello::Web->to_app(config => $config);
};
