use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Large;
use parent qw(Amon2::Setup::Flavor);
use File::Path ();

our $VERSION = '6.02';

sub admin_script {
    my $self = shift;
    my $admin_script = 'script/' . lc($self->{dist}) . '-admin-server';
}

sub web_script {
    my $self = shift;
    my $web_script = 'script/' . lc($self->{dist}) . '-web-server';
}

sub run {
    my $self = shift;

    my $admin_script = $self->admin_script;
    my $web_script = $self->web_script;

    # write code.
    for my $moniker (qw(web admin)) {
        # static files
        $self->write_assets("static/${moniker}");

        $self->render_file( "tmpl/${moniker}/index.tx",          "Basic/tmpl/index.tx" );
        $self->render_file( "tmpl/${moniker}/include/layout.tx", "Basic/tmpl/include/layout.tx" );
        $self->render_file( "tmpl/${moniker}/include/pager.tx",  "Basic/tmpl/include/pager.tx" );

        $self->write_file("static/${moniker}/img/.gitignore", '');
        $self->write_file("static/${moniker}/robots.txt", '');

        $self->render_file("static/${moniker}/js/main.js",   "Basic/static/js/main.js");
        $self->render_file("static/${moniker}/css/main.css", "Basic/static/css/main.css");
    }
    $self->render_file('tmpl/admin/error.tx', 'Large/tmpl/admin/error.tx');
    $self->render_file('tmpl/web/error.tx', 'Large/tmpl/web/error.tx');
    $self->render_file('tmpl/admin/index.tx', 'Large/tmpl/admin/index.tx');

    $self->render_file('tmpl/admin/include/layout.tx', 'Large/tmpl/admin/include/layout.tx');

    $self->render_file('static/admin/css/admin.css', 'Large/static/admin/css/admin.css', {color1 => '#117711', color2 => '#119911'});

    $self->render_file('tmpl/admin/include/sidebar.tx', 'Large/tmpl/admin/include/sidebar.tx');

    # building stuff
    $self->render_file( 'Build.PL', 'Minimum/Build.PL' );
    $self->render_file( 'minil.toml', 'Minimum/minil.toml' );
    $self->render_file( 'builder/MyBuilder.pm', 'Minimum/builder/MyBuilder.pm' );


    $self->render_file('db/.gitignore', 'Basic/db/dot.gitignore');

    # configuration files
    for my $env (qw(development production test)) {
        $self->render_file( "config/${env}.pl", 'Basic/config/__ENV__.pl', { env => $env } );
    }

    $self->render_file( 'sql/mysql.sql',  'Large/sql/mysql.sql' );
    $self->render_file( 'sql/sqlite.sql', 'Large/sql/sqlite.sql' );

    $self->render_file( 't/00_compile.t',     'Large/t/00_compile.t' );
    $self->render_file( 't/web/01_root.t',        'Minimum/t/01_root.t', {
        psgi_file => $web_script,
    });
    $self->render_file( 't/02_mech.t',        'Minimum/t/02_mech.t', {
        psgi_file => $web_script,
    });
    $self->render_file( 't/03_assets.t',      'Basic/t/03_assets.t', {
        psgi_file => $web_script,
    });
    $self->render_file( 't/04_admin.t',       'Large/t/04_admin.t', {
        psgi_file => $admin_script,
    });
    $self->render_file( 't/06_jshint.t',      'Basic/t/06_jshint.t' );
    $self->render_file( 't/07_mech_links.t',  'Large/t/07_mech_links.t', {
        psgi_file => $web_script,
    });
    $self->render_file( 't/Util.pm',          'Basic/t/Util.pm' );
    $self->render_file( 'xt/01_pod.t',        'Minimum/xt/01_pod.t' );
    $self->render_file( 'xt/02_perlcritic.t', 'Basic/xt/02_perlcritic.t' );


    $self->create_cpanfile(
        {
            'Amon2::Util'                        => 0,
            'Amon2::Web'                         => 0,
            'Amon2::Web::Dispatcher::RouterBoom' => 0,
            'DBI'                                => 0,
            'File::ShareDir'                     => 0,
            'Getopt::Long'                       => 0,
            'HTTP::Session2::ClientStore'        => 0,
            'Module::Build'                      => 0,
            'Module::Find'                       => 0,        # load controllers
            'Module::Functions'                  => 2,        # Dispatcher
            'Plack::App::File'                   => 0,
            'Plack::Builder'                     => 0,
            'Plack::Loader'                      => 0,
            'Plack::Session::Store::DBI'         => 0,
            'Router::Boom'                       => '0.06',
            'Teng'                               => 0,
            'Teng::Row'                          => 0,
            'Teng::Schema::Declare'              => 0,
            'parent'                             => 0,
        }
    );

    $self->render_file('.gitignore', 'Basic/dot.gitignore');
    $self->render_file('.proverc', 'Basic/dot.proverc');

    {
        my %status = (
            '503' => 'Service Unavailable',
            '502' => 'Bad Gateway',
            '500' => 'Internal Server Error',
            '504' => 'Gateway Timeout',
            '404' => 'Not Found'
        );
        while (my ($status, $status_message) = each %status) {
            $self->render_file(
                "static/$status.html",
                "Basic/static/__STATUS__.html",
                { status => $status, status_message => $status_message }
            );
        }
    }

    $self->render_file( 'lib/<<PATH>>.pm',                   'Basic/lib/__PATH__.pm' );
    $self->render_file( 'lib/<<PATH>>/DB.pm',                'Basic/lib/__PATH__/DB.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Schema.pm',         'Basic/lib/__PATH__/DB/Schema.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Row.pm',            'Basic/lib/__PATH__/DB/Row.pm' );

    $self->render_file("lib/<<PATH>>/Web/C/Account.pm", 'Large/lib/__PATH__/Web/C/Account.pm');
    for my $moniker (qw(Web Admin)) {
        $self->render_file("lib/<<PATH>>/$moniker.pm", 'Large/lib/__PATH__/__MONIKER__.pm', {moniker => $moniker});
        $self->render_file("lib/<<PATH>>/$moniker/Dispatcher.pm", 'Large/lib/__PATH__/__MONIKER__/Dispatcher.pm', {moniker => $moniker});
        $self->render_file("lib/<<PATH>>/$moniker/C/Root.pm", 'Large/lib/__PATH__/__MONIKER__/C/Root.pm', {moniker => $moniker});
        $self->render_file( "lib/<<PATH>>/${moniker}/ViewFunctions.pm", 'Minimum/lib/__PATH__/Web/ViewFunctions.pm', {
            package => "$self->{module}::${moniker}::ViewFunctions",
        });
        $self->render_file( "lib/<<PATH>>/${moniker}/Plugin/Session.pm", 'Basic/lib/__PATH__/Web/Plugin/Session.pm', {
            package => "$self->{module}::${moniker}::Plugin::Session",
        });
        $self->render_file( "lib/<<PATH>>/${moniker}/View.pm", 'Minimum/lib/__PATH__/Web/View.pm', {
            package   => "$self->{module}::${moniker}::View",
            tmpl_path => "tmpl/" . lc($moniker),
            view_functions_package => "$self->{module}::${moniker}::ViewFunctions",
        });
    }


    $self->render_file( $admin_script,     'Large/script/admin.pl' );
    $self->render_file( $web_script,       'Large/script/web.pl' );
}

sub show_banner {
    my $self = shift;

    printf <<'...', $self->web_script, $self->admin_script;
--------------------------------------------------------------

Setup script was done! You are ready to run the skelton.

You need to install the dependencies by:

    > carton install

Setup the SQLite3 database:

    > sqlite3 db/development.db < sql/sqlite.sql

And then, run your application server:

    > carton exec perl -Ilib %s

You can run the admin sites by following:

    > carton exec perl -Ilib %s

--------------------------------------------------------------
...
}

1;

__END__

=head1 NAME

Amon2::Setup::Flavor::Large - Flavor with admin pages

=head1 DESCRIPTION

This is an Amon2 flavor based on Amon2::Setup::Flavor::Basic.

