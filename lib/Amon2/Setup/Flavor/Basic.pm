use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Basic;
use parent qw(Amon2::Setup::Flavor::Minimum);

my @ASSETS = qw/
    jQuery Bootstrap ES5Shim MicroTemplateJS StrftimeJS SprintfJS
    MicroLocationJS MicroDispatcherJS
/;

sub write_static_files {
    my ($self, $base) = @_;
    $base ||= 'static';

    for my $asset (@ASSETS) {
        $self->write_asset($asset, $base);
    }

    $self->write_file("$base/img/.gitignore", '');

    $self->write_file("$base/robots.txt", '');

    $self->write_file("$base/js/main.js", <<'...');
if (typeof(window.console) == "undefined") { console = {}; console.log = console.warn = console.error = function(a) {}; }

$(function () {
});
...

    $self->write_file("$base/css/main.css", <<'...');
body {
    margin-top: 50px;
}

footer {
    text-align: right;
    padding-right: 10px;
    padding-top: 2px; }
    footer a {
        text-decoration: none;
        color: black;
        font-weight: bold;
    }

/* smart phones */
@media screen and (max-device-width: 480px) {
}
...
}

sub write_templates {
    my ($self, $base) = @_;
    $base ||= 'tmpl';

    $self->write_file("$base/index.tt", <<'...');
[% WRAPPER 'include/layout.tt' %]

<h1 style="padding: 70px; text-align: center; font-size: 80px; line-height: 1; letter-spacing: -2px;">Hello, Amon2 world!</h1>

<hr />

<style>
    .marketing .row {
        margin-top: 20px;
    }
</style>
<div class="marketing">
    <h1 style="text-align: center; font-size: 280%;">Battery Included?</h1>

    <div class="row">
        <div class="span4">
            <h2>CSS Library</h2>
            <div>
                Current version of Amon2 using twitter's bootstrap.css as a default CSS library.<br />
                If you want to learn it, please access to <a href="http://twitter.github.com/bootstrap/">twitter.github.com/bootstrap/</a>
            </div>
        </div>

        <div class="span4">
            <h2>JS Library</h2>
            <div>
                <a href="http://jquery.com/">jQuery</a> included.
                <ul>
                    <li>es5-shim.min.js</li>
                    <li>micro-location.js</li>
                    <li>micro_template.js</li>
                    <li>sprintf-0.7-beta1.js</li>
                    <li>strftime.js</li>
                </ul>
            </div>
        </div>

        <div class="span4">
            <h2>Template Engine</h2>
            <div>
                Amon2 uses <B>Text::Xslate</B>(TTerse) as a primary template engine.<br />
                But you can use any template engine easily.
            </div>
        </div>
    </div>

    <div class="row">
        <div class="span4">
            <h2>O/R Mapper?</h2>
            <div>
                There is no O/R Mapper support. But I recommend use Teng.<br />
                You can integrate Teng very easily.<br />
                Refer to <a href="http://amon.64p.org/database.html#teng">this page</a> for more details.
            </div>
        </div>
    </div>
</div>

<hr />

<div class="row">
    <h1 style="text-align: center;">Amon2 is right for you if ...</h1>
    <div class="span24">
        <ul>
        <li>You need exceptional performance.</li>
        <li>You want a framework with a small footprint.</li>
        <li>You want a framework that requires nearly zero configuration.</li>
        </ul>
    </div>
</div>

<hr />

<section class="row">
    <div class="span12">
        <h1>Documents?</h1>
        <p>Complete docs are available on <a href="http://amon.64p.org/">amon.64p.org</a></p>
        <p>And there are module specific docs on <a href="https://metacpan.org/release/Amon2">CPAN</a></p>
    </div>
</section>

[% END %]
...

    $self->write_file("$base/include/layout.tt", <<'...');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<%= $dist %>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="Content-Script-Type" content="text/javascript" />
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0" />
    <meta name="format-detection" content="telephone=no" />
<% $tags -%>
    <link href="[% static_file('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <script src="[% static_file('/static/js/main.js') %]"></script>
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] id="[% bodyID %]"[% END %]>
    <div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container">
                <a class="brand" href="#"><% $dist %></a>
                <div class="nav-collapse">
                    <ul class="nav">
                        <li class="active"><a href="#">Home</a></li>
                        <li><a href="#">Link</a></li>
                        <li><a href="#">Link</a></li>
                        <li><a href="#">Link</a></li>
                    </ul>
                </div>
            </div>
        </div><!-- /.navbar-inner -->
    </div><!-- /.navbar -->
    <div class="container">
        <div id="main">
            [% content %]
        </div>
        <footer class="footer">
            Powered by <a href="http://amon.64p.org/">Amon2</a>
        </footer>
    </div>
</body>
</html>
...

    $self->write_file("$base/include/pager.tt", <<'...');
[% IF pager %]
    <div class="pagination">
        <ul>
            [% IF pager.previous_page %]
                <li class="prev"><a href="[% uri_with({page => pager.previous_page}) %]" rel="previous">&larr; Back</a><li>
            [% ELSE %]
                <li class="prev disabled"><a href="#">&larr; Back</a><li>
            [% END %]

            [% IF pager.can('pages_in_navigation') %]
                [% # IF Data::Page::Navigation is loaded %]
                [% FOR p IN pager.pages_in_navigation(5) %]
                    <li [% IF p==pager.current_page %]class="active"[% END %]><a href="[% uri_with({page => p}) %]">[% p %]</a></li>
                [% END %]
            [% ELSE %]
                <li><a href="#">[% pager.current_page %]</a></li>
            [% END %]

            [% IF pager.next_page %]
                <li class="next"><a href="[% uri_with({page => pager.next_page}) %]" rel="next">Next &rarr;</a><li>
            [% ELSE %]
                <li class="next disabled"><a href="#">Next &rarr;</a><li>
            [% END %]
        </ul>
    </div>
[% END %]
...
}

sub run {
    my $self = shift;

    for (@ASSETS) {
        $self->load_asset($_);
    }

    $self->SUPER::run();

    $self->write_static_files();

    $self->write_file('app.psgi', <<'...', {header => $self->psgi_header});
<% header %>
use <% $module %>::Web;
use <% $module %>;
use Plack::Session::Store::DBI;
use Plack::Session::State::Cookie;
use DBI;

{
    my $c = <% $module %>->new();
    $c->setup_schema();
}
my $db_config = <% $module %>->config->{DBI} || die "Missing configuration for DBI";
builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static');
    enable 'Plack::Middleware::ReverseProxy';
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                DBI->connect( @$db_config )
                    or die $DBI::errstr;
            }
        ),
        state => Plack::Session::State::Cookie->new(
            httponly => 1,
        );
    <% $module %>::Web->to_app();
};
...

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='3.84';
use 5.008001;

__PACKAGE__->load_plugin(qw/DBI/);

# initialize database
use DBI;
sub setup_schema {
    my $self = shift;
    my $dbh = $self->dbh();
    my $driver_name = $dbh->{Driver}->{Name};
    my $fname = lc("sql/${driver_name}.sql");
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    my $source = do { local $/; <$fh> };
    for my $stmt (split /;/, $source) {
        next unless $stmt =~ /\S/;
        $dbh->do($stmt) or die $dbh->errstr();
    }
}

1;
...

    $self->create_web_pms();
    $self->create_view();

    $self->write_file('db/.gitignore', <<'...');
*
!.gitignore
...

    for my $env (qw(development deployment test)) {
        $self->write_file("config/${env}.pl", <<'...', {env => $env});
use File::Spec;
use File::Basename qw(dirname);
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath = File::Spec->catfile($basedir, 'db', '<% $env %>.db');
+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbpath", '', '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...
    }

    $self->write_file("sql/mysql.sql", <<'...');
CREATE TABLE IF NOT EXISTS sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
);
...
    $self->write_file("sql/sqlite.sql", <<'...');
CREATE TABLE IF NOT EXISTS sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
);
...

    $self->write_file("t/00_compile.t", <<'...');
use strict;
use warnings;
use utf8;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
    <% $module %>::Web::ViewFunctions
    <% $module %>::Web::Dispatcher
);

done_testing;
...

    $self->write_file("xt/02_perlcritic.t", <<'...');
use strict;
use Test::More;
eval q{
    use Perl::Critic 1.113;
    use Test::Perl::Critic 1.02 -exclude => [
        'Subroutines::ProhibitSubroutinePrototypes',
        'Subroutines::ProhibitExplicitReturnUndef',
        'TestingAndDebugging::ProhibitNoStrict',
        'ControlStructures::ProhibitMutatingListFunctions',
    ];
};
plan skip_all => "Test::Perl::Critic 1.02+ and Perl::Critic 1.113+ is not installed." if $@;
all_critic_ok('lib');
...

    $self->write_file('.gitignore', <<'...');
Makefile
/inc/
MANIFEST
*.bak
*.old
nytprof.out
nytprof/
*.db
/blib/
pm_to_blib
META.json
META.yml
MYMETA.json
MYMETA.yml
/Build
/_build/
/local/
/.carton/
...

    $self->write_file('t/03_assets.t', <<'...');
use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'app.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        for my $fname (qw(static/bootstrap/css/bootstrap.css robots.txt)) {
            my $req = HTTP::Request->new(GET => "http://localhost/$fname");
            my $res = $cb->($req);
            is($res->code, 200, $fname) or diag $res->content;
        }
    };

done_testing;
...

    $self->write_file('.proverc', <<'...');
-l
-r t
-Mt::Util
...

    $self->write_file('t/06_jslint.t', <<'...');
#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Text::SimpleTable';
use File::Basename;

plan skip_all => 'this test requires "jshint" command'
  unless `jshint --version` =~ /\d/;

my @files = (<static/*/*.js>, <static/*/*/*.js>, <static/*/*/*/*.js>);

my %WHITE_LIST = map { $_ => 1 } qw(
    bootstrap.js
    bootstrap.min.js
    es5-shim.min.js
    micro-location.js
    micro_template.js
);

my $table = Text::SimpleTable->new( 25, 5 );

for my $file (@files) {
    next if $WHITE_LIST{basename($file)};
    next if basename($file) =~ /jquery-[0-9.]+.min.js$/;

    my $out = `jshint $file`;
    my $err = 0;
    if ( $out =~ /(\d+) errors?/ ) {
        ( $err ) = ( $1 );
        is($err, 0, $file)
            or note $out;
    }
    else {
        ok(1);
    }
    $table->row( basename($file), $err );
}

note $table->draw;

done_testing;
...

    for my $status (qw/404 500 502 503 504/) {
        $self->write_status_file("static/$status.html", $status);
    }
}

sub write_status_file {
    my ($self, $fname, $status) = @_;

    my $message = {
        '503' => 'Service Unavailable',
        '502' => 'Bad Gateway',
        '500' => 'Internal Server Error',
        '504' => 'Gateway Timeout',
        '404' => 'Not Found'
    }->{$status};
    $self->write_file($fname, <<'...', status => $status, status_message => $message);
<!doctype html>
<html>
    <head>
        <meta charset=utf-8 />
        <style type="text/css">
            body {
                text-align: center;
                font-family: 'Menlo', 'Monaco', Courier, monospace;
                background-color: whitesmoke;
                padding-top: 10%;
            }
            .number {
                font-size: 800%;
                font-weight: bold;
                margin-bottom: 40px;
            }
            .message {
                font-size: 400%;
            }
        </style>
    </head>
    <body>
        <div class="number"><%= $status %></div>
        <div class="message"><%= $status_message %></div>
    </body>
</html>
...
}

sub create_web_pms {
    my ($self) = @_;

    $self->write_file('lib/<<PATH>>/Web.pm', <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return (<% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::CSRFDefender' => {
        post_only => 1,
    },
);

# setup view
use <% $module %>::Web::View;
{
    my $view = <% $module %>::Web::View->make_instance(__PACKAGE__);
    sub create_view { $view }
}

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

1;
...

    $self->write_file("lib/<<PATH>>/Web/Dispatcher.pm", <<'...');
package <% $module %>::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    return $c->render('index.tt');
};

post '/account/logout' => sub {
    my ($c) = @_;
    $c->session->expire();
    return $c->redirect('/');
};

1;
...
}

sub create_makefile_pl {
    my ($self, $prereq_pm) = @_;

    $self->SUPER::create_makefile_pl(
        +{
            %{ $prereq_pm || {} },
            'HTML::FillInForm::Lite'          => '1.11',
            'Time::Piece'                     => '1.20',
            'Plack::Session'                  => '0.14',
            'DBD::SQLite'                     => '1.33',
            'Plack::Middleware::Session'      => 0,
            'Plack::Middleware::ReverseProxy' => '0.09',
            'JSON'                            => '2.50',
            'Amon2::DBI'                      => '0.30',
            'DBD::SQLite'                     => '1.33',
            'Test::WWW::Mechanize::PSGI'      => 0,
        },
    );
}

sub create_t_02_mech_t {
    my ($self, $more) = @_;
    $more ||= '';
    $self->SUPER::create_t_02_mech_t(<<'...' . $more);
...
}

sub create_t_util_pm {
    my ($self, $export, $more) = @_;
    $export ||= [];
    $more ||= '';

    $self->SUPER::create_t_util_pm([@$export, qw(slurp)], $more . "\n" . <<'...');
sub slurp {
    my $fname = shift;
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    do { local $/; <$fh> };
}

# initialize database
use <% $module %>;
{
    unlink 'db/test.db' if -f 'db/test.db';

    my $c = <% $module %>->new();
    $c->setup_schema();
}
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
