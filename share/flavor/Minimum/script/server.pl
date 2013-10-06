use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '../lib');
use Plack::Builder;

%% block load_modules -> {
use <% $module %>::Web;
%% }

%% block app -> {
my $app = builder {
    enable 'Plack::Middleware::AccessLog';
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__), '..');
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'static');
    <% $module %>::Web->to_app();
};
%% }
unless (caller) {
    my $port        = 5000;
    my $host        = '127.0.0.1';
    my $max_workers = 4;

    require Getopt::Long;
    require Plack::Loader;
    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'p|port=i'      => \$port,
        'host=s'      => \$host,
        'max-workers' => \$max_workers,
        'version!'    => \my $version,
    );
    if ($version) {
        print "<% $module %>: $<% $module %>::VERSION\n";
        exit 0;
    }

    print "<% $module %>: http://${host}:${port}/\n";

    my $loader = Plack::Loader->load('Starlet',
        port        => $port,
        host        => $host,
        max_workers => $max_workers,
    );
    return $loader->run($app);
}
return $app;
