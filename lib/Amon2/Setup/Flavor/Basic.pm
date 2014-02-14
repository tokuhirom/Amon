use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Basic;
use parent qw(Amon2::Setup::Flavor);

our $VERSION = '6.02';

sub run {
    my $self = shift;

    # write code.
    $self->render_file( "tmpl/index.tx",          "Basic/tmpl/index.tx" );
    $self->render_file( "tmpl/include/layout.tx", "Basic/tmpl/include/layout.tx" );
    $self->render_file( "tmpl/include/pager.tx",  "Basic/tmpl/include/pager.tx" );

    $self->render_file( 'lib/<<PATH>>.pm',                   'Basic/lib/__PATH__.pm' );
    $self->render_file( 'lib/<<PATH>>/Web.pm',               'Basic/lib/__PATH__/Web.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/Plugin/Session.pm','Basic/lib/__PATH__/Web/Plugin/Session.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/Dispatcher.pm',    'Basic/lib/__PATH__/Web/Dispatcher.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/View.pm',          'Minimum/lib/__PATH__/Web/View.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/ViewFunctions.pm', 'Minimum/lib/__PATH__/Web/ViewFunctions.pm' );
    $self->render_file( 'lib/<<PATH>>/DB.pm',                'Basic/lib/__PATH__/DB.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Schema.pm',         'Basic/lib/__PATH__/DB/Schema.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Row.pm',            'Basic/lib/__PATH__/DB/Row.pm' );

    $self->render_file( $self->psgi_file, 'Basic/script/server.pl' );
    $self->render_file( 'Build.PL', 'Minimum/Build.PL' );
    $self->render_file( 'minil.toml', 'Minimum/minil.toml' );
    $self->render_file( 'builder/MyBuilder.pm', 'Minimum/builder/MyBuilder.pm' );


    $self->create_cpanfile({
        'HTML::FillInForm::Lite'          => '1.11',
        'Time::Piece'                     => '1.20',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'JSON'                            => '2.50',
        'Teng'                            => '0.18',
        'DBD::SQLite'                     => '1.33',
        'Test::WWW::Mechanize::PSGI'      => 0,
        'Router::Boom'                    => '0.06',
        'HTTP::Session2'                  => '0.04',
    });

    # static files
    $self->write_assets();

    $self->write_file("static/img/.gitignore", '');
    $self->write_file("static/robots.txt", '');

    $self->render_file("static/js/main.js",   "Basic/static/js/main.js");
    $self->render_file("static/css/main.css", "Basic/static/css/main.css");

    $self->render_file('db/.gitignore', 'Basic/db/dot.gitignore');

    # configuration files
    for my $env (qw(development production test)) {
        $self->render_file( "config/${env}.pl", 'Basic/config/__ENV__.pl', { env => $env } );
    }

    $self->render_file( 'sql/mysql.sql',  'Basic/sql/mysql.sql' );
    $self->render_file( 'sql/sqlite.sql', 'Basic/sql/sqlite.sql' );

    $self->render_file( 't/Util.pm',      'Basic/t/Util.pm' );
    $self->render_file( 't/00_compile.t',     'Basic/t/00_compile.t' );
    $self->render_file( 't/01_root.t',    'Minimum/t/01_root.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file( 't/02_mech.t',    'Minimum/t/02_mech.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file( 't/03_assets.t',      'Basic/t/03_assets.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file( 't/06_jshint.t',      'Basic/t/06_jshint.t' );
    $self->render_file( 'xt/01_pod.t',    'Minimum/xt/01_pod.t' );
    $self->render_file( 'xt/02_perlcritic.t', 'Basic/xt/02_perlcritic.t' );

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
}

sub psgi_file {
    my $self = shift;
    'script/' . lc($self->{dist}) . '-server';
}

sub show_banner {
    my $self = shift;

    printf <<'...', $self->psgi_file;
--------------------------------------------------------------

Setup script was done! You are ready to run the skelton.

You need to install the dependencies by:

    > carton install

And then, run your application server:

    > carton exec perl -Ilib %s

--------------------------------------------------------------
...
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Basic - Basic flavor selected by default

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Basic MyApp

=head1 DESCRIPTION

This is a basic flavor for Amon2. This is the default flavor.

=head1 AUTHOR

Tokuhiro Matsuno
