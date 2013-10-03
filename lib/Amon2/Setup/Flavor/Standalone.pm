use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Standalone;
use parent qw(Amon2::Setup::Flavor::Basic);
use File::Copy::Recursive ();

sub psgi_file {
    my $self = shift;
    return 'script/' . lc($self->{dist}) . '-server';
}

sub run {
    my $self = shift;
    $self->SUPER::run();

    # regen view for moving template directory.
    $self->create_view(tmpl_path => 'share/tmpl/');

    my $psgi_file = $self->psgi_file;

    $self->create_main_pm(make_local_context => 1);
    $self->create_view_functions(context_class => $self->{module});

    $self->write_file($psgi_file, <<'...', {header => $self->psgi_header});
<% header %>
use lib File::Spec->catdir(dirname(__FILE__), '..', 'lib');
use <% $module %>::Web;
use <% $module %>;
use Plack::Session::Store::File;
use Plack::Session::State::Cookie;
use URI::Escape;
use File::Path ();
use Getopt::Long;
use Plack::Loader;

my $session_dir = File::Spec->catdir(File::Spec->tmpdir, uri_escape("<% $module %>") . "-$<" );
File::Path::mkpath($session_dir);
my $app = builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'share');
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'share', 'static');
    enable 'Plack::Middleware::ReverseProxy';

    # If you want to run the app on multiple servers,
    # you need to use Plack::Sesion::Store::DBI or ::Store::Cache.
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::File->new(
            dir => $session_dir,
        ),
        state => Plack::Session::State::Cookie->new(
            httponly => 1,
        );
    <% $module %>::Web->to_app();
};

unless (caller) {
    my $port        = 5000;
    my $host        = '127.0.0.1';
    my $max_workers = 4;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'port=i' => \$port,
        'host=s' => \$host,
        'max-workers' => \$max_workers,
        'version!' => \my $version,
    );
    if ($version) {
        print "<% $module %>: $<% $module %>::VERSION\n";
        exit 0;
    }

    my $loader = Plack::Loader->load('Starlet',
        port        => $port,
        host        => $host,
        max_workers => $max_workers,
    );
    return $loader->run($app);
}
return $app;
...

    $self->create_t_01_root_t(psgi_file => $psgi_file);
    $self->create_t_02_mech_t('', psgi_file => $psgi_file);
    $self->create_t_03_assets_t(psgi_file => $psgi_file);
    $self->create_t_06_jshint_t(static_dir => 'share/static');

    # move dirs.
    File::Copy::Recursive::rmove('tmpl', 'share/tmpl');
    File::Copy::Recursive::rmove('static', 'share/static');

    # remove app.psgi
    unlink 'app.psgi';
}

sub show_banner {
    my $self = shift;

    printf <<'...', $self->psgi_file;
--------------------------------------------------------------

Setup script was done! You are ready to run the skelton.

You need to install the dependencies by:

    %% cpanm --installdeps .

And then, run your application server:

    %% perl -Ilib %s

--------------------------------------------------------------
...
}

1;
