use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Basic;
use parent qw(Amon2::Setup::Flavor::Minimum);

sub run {
    my $self = shift;

    # write code.
    $self->render_file( "tmpl/index.tx",          "Basic/tmpl/index.tx" );
    $self->render_file( "tmpl/include/layout.tx", "Basic/tmpl/include/layout.tx" );
    $self->render_file( "tmpl/include/pager.tx",  "Basic/tmpl/include/pager.tx" );

    $self->render_file( 'lib/<<PATH>>.pm',                   'Basic/lib/__PATH__.pm' );
    $self->render_file( 'lib/<<PATH>>/Web.pm',               'Basic/lib/__PATH__/Web.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/Dispatcher.pm',    'Basic/lib/__PATH__/Web/Dispatcher.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/View.pm',          'Minimum/lib/__PATH__/Web/View.pm' );
    $self->render_file( 'lib/<<PATH>>/Web/ViewFunctions.pm', 'Minimum/lib/__PATH__/Web/ViewFunctions.pm' );
    $self->render_file( 'lib/<<PATH>>/DB.pm',                'Basic/lib/__PATH__/DB.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Schema.pm',         'Basic/lib/__PATH__/DB/Schema.pm' );
    $self->render_file( 'lib/<<PATH>>/DB/Row.pm',            'Basic/lib/__PATH__/DB/Row.pm' );

    $self->render_file( $self->psgi_file, 'Basic/script/server.pl' );
    $self->render_file( 'Build.PL', 'Minimum/Build.PL' );


    $self->create_cpanfile();

    # static files
    my @assets = qw(
        jQuery Bootstrap ES5Shim MicroTemplateJS StrftimeJS SprintfJS
        MicroLocationJS MicroDispatcherJS
    );

    for my $asset (@assets) {
        $self->load_asset($asset);
        $self->write_asset($asset, 'static');
    }

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

sub create_cpanfile {
    my ($self, $prereq_pm) = @_;

    $self->SUPER::create_cpanfile(
        +{
            %{ $prereq_pm || {} },
            'HTML::FillInForm::Lite'          => '1.11',
            'Time::Piece'                     => '1.20',
            'Plack::Session'                  => '0.14',
            'Plack::Middleware::Session'      => 0,
            'Plack::Middleware::ReverseProxy' => '0.09',
            'JSON'                            => '2.50',
            'Teng'                            => '0.18',
            'DBD::SQLite'                     => '1.33',
            'Test::WWW::Mechanize::PSGI'      => 0,
        },
    );
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
