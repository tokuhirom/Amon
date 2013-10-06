use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Large;
use parent qw(Amon2::Setup::Flavor::Basic);
use File::Path ();

sub create_cpanfile {
    my ($self, $prereq_pm) = @_;

    $self->SUPER::create_cpanfile(
        +{
            %{ $prereq_pm || {} },
            'String::CamelCase' => '0.02',
            'Module::Find'      => 0, # load controllers
            'Module::Functions' => 2, # Dispatcher
        },
    );
}

sub run {
    my $self = shift;

    # write code.
    for my $moniker (qw(pc admin)) {
        # static files
        my @assets = qw(
            jQuery Bootstrap ES5Shim MicroTemplateJS StrftimeJS SprintfJS
            MicroLocationJS MicroDispatcherJS
        );

        for my $asset (@assets) {
            $self->load_asset($asset);
            $self->write_asset($asset, "static/${moniker}");
        }

        $self->render_file( "tmpl/${moniker}/index.tx",          "Basic/tmpl/index.tx" );
        $self->render_file( "tmpl/${moniker}/include/layout.tx", "Basic/tmpl/include/layout.tx" );
        $self->render_file( "tmpl/${moniker}/include/pager.tx",  "Basic/tmpl/include/pager.tx" );

        $self->write_file("static/${moniker}/img/.gitignore", '');
        $self->write_file("static/${moniker}/robots.txt", '');

        $self->render_file("static/${moniker}/js/main.js",   "Basic/static/js/main.js");
        $self->render_file("static/${moniker}/css/main.css", "Basic/static/css/main.css");
    }
    $self->render_file('tmpl/admin/error.tx', 'Large/tmpl/admin/error.tx');
    $self->render_file('tmpl/pc/error.tx', 'Large/tmpl/pc/error.tx');
    $self->render_file('tmpl/admin/index.tx', 'Large/tmpl/admin/index.tx');

    $self->render_file('tmpl/admin/include/layout.tx', 'Large/tmpl/admin/include/layout.tx');

    $self->render_file('static/admin/css/admin.css', 'Large/static/admin/css/admin.css', {color1 => '#117711', color2 => '#119911'});

    $self->render_file('tmpl/admin/include/sidebar.tx', 'Large/tmpl/admin/include/sidebar.tx');

    $self->render_file( 'Build.PL', 'Minimum/Build.PL' );


    $self->render_file('db/.gitignore', 'Basic/db/dot.gitignore');

    # configuration files
    for my $env (qw(development production test)) {
        $self->render_file( "config/${env}.pl", 'Basic/config/__ENV__.pl', { env => $env } );
    }

    $self->render_file( 'sql/mysql.sql',  'Large/sql/mysql.sql' );
    $self->render_file( 'sql/sqlite.sql', 'Large/sql/sqlite.sql' );

    $self->render_file( 't/00_compile.t',     'Large/t/00_compile.t' );
    $self->render_file( 't/01_root.t',        'Minimum/t/01_root.t' );
    $self->render_file( 't/02_mech.t',        'Minimum/t/02_mech.t' );
    $self->render_file( 't/03_assets.t',      'Basic/t/03_assets.t' );
    $self->render_file( 't/04_admin.t',       'Large/t/04_admin.t' );
    $self->render_file( 't/06_jshint.t',      'Basic/t/06_jshint.t' );
    $self->render_file( 't/07_mech_links.t',  'Large/t/07_mech_links.t' );
    $self->render_file( 't/Util.pm',          'Basic/t/Util.pm' );
    $self->render_file( 'xt/01_pod.t',        'Minimum/xt/01_pod.t' );
    $self->render_file( 'xt/02_perlcritic.t', 'Basic/xt/02_perlcritic.t' );


    $self->create_cpanfile();

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

    $self->render_file("lib/<<PATH>>/PC/C/Account.pm", 'Large/lib/__PATH__/PC/C/Account.pm');
    for my $moniker (qw(PC Admin)) {
        $self->render_file("lib/<<PATH>>/$moniker.pm", 'Large/lib/__PATH__/__MONIKER__.pm', {moniker => $moniker});
        $self->render_file("lib/<<PATH>>/$moniker/Dispatcher.pm", 'Large/lib/__PATH__/__MONIKER__/Dispatcher.pm', {moniker => $moniker});
        $self->render_file("lib/<<PATH>>/$moniker/C/Root.pm", 'Large/lib/__PATH__/__MONIKER__/C/Root.pm', {moniker => $moniker});
        $self->render_file( "lib/<<PATH>>/${moniker}/ViewFunctions.pm", 'Minimum/lib/__PATH__/Web/ViewFunctions.pm', {
            package => "$self->{module}::${moniker}::ViewFunctions",
        });
        $self->render_file( "lib/<<PATH>>/${moniker}/View.pm", 'Minimum/lib/__PATH__/Web/View.pm', {
            package   => "$self->{module}::${moniker}::View",
            tmpl_path => "tmpl/" . lc($moniker),
            view_functions_package => "$self->{module}::${moniker}::ViewFunctions",
        });
    }


    $self->render_file( 'admin.psgi',     'Large/admin.psgi' );
    $self->render_file( 'pc.psgi',     'Large/pc.psgi' );

    $self->write_file('app.psgi', <<'...');
use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use <% $module %>::PC;
use Plack::Util;
use Plack::Builder;

builder {
    mount '/admin/' => Plack::Util::load_psgi('admin.psgi');
    mount '/' => Plack::Util::load_psgi('pc.psgi');
};
...

}

sub show_banner {
    print <<'...';
--------------------------------------------------------------

Setup script was done! You are ready to run the skelton.

You need to install the dependencies by:

    % cpanm --installdeps .

Setup the SQLite3 database:

    % sqlite3 db/development.db < sql/sqlite.sql

And then, run your application server:

    % plackup -Ilib app.psgi

--------------------------------------------------------------
...
}

1;

__END__

=head1 NAME

Amon2::Setup::Flavor::Large - Flavor with admin pages

=head1 DESCRIPTION

This is an Amon2 flavor based on Amon2::Setup::Flavor::Basic.

