use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Basic;
use parent qw(Amon2::Setup::Flavor::Minimum);
use HTTP::Status qw/status_message/;

sub run {
    my $self = shift;

    $self->SUPER::run();

    $self->mkpath('static/img/');
    $self->mkpath('static/js/');

    $self->load_asset('jQuery');
    $self->load_asset('Bootstrap');

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

# __PACKAGE__->load_plugin(qw/DBI/);

1;
...

    $self->write_file('lib/<<PATH>>/Web.pm', <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

# load all controller classes
use Module::Find ();
Module::Find::useall("<% $module %>::Web::C");

# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return <% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
        %$view_conf
    });
    sub create_view { $view }
}

# load plugins
use HTTP::Session::Store::File;
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::NoCache', # do not cache the dynamic content by default
    'Web::CSRFDefender',
    'Web::HTTPSession' => {
        state => 'Cookie',
        store => HTTP::Session::Store::File->new(
            dir => File::Spec->tmpdir(),
        )
    },
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
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
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};

1;
...

    $self->write_file("config/development.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=development.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("config/deployment.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=deployment.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("config/test.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=test.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("sql/my.sql", '');
    $self->write_file("sql/sqlite3.sql", '');

    $self->write_file('tmpl/index.tt', <<'...');
[% WRAPPER 'include/layout.tt' %]

<div class="row">
    <div class="span10">
        <h1>Hello, Amon2 world!</h1>

        <h2>For benchmarkers...</h2>
        <p>If you want to benchmarking between Plack based web application frameworks, you should use <B>Amon2::Setup::Flavor::Minimum</B> instead.</p>
        <p>You can use it as following one liner:</p>
        <pre>% amon2-setup.pl --flavor Minimum <% $module %></pre>
    </div>
    <div class="span6">
        <p>Amon2 is right for you if ...</p>
        <ul>
        <li>You need exceptional performance.</li>
        <li>You want a framework with a small footprint.</li>
        <li>You want a framework that requires nearly zero configuration.</li>
        </ul>
    </div>
</div>

<hr />

<h1>Components?</h1>

<section class="row">
    <div class="span4">
        <h2>CSS Library</h2>
    </div>
    <div class="span12">
        Current version of Amon2 using twitter's bootstrap.css as a default CSS library.<br />
        If you want to learn it, please access to <a href="http://twitter.github.com/bootstrap/">twitter.github.com/bootstrap/</a>
    </div>
</section>

<hr />

<section class="row">
    <div class="span4">
        <h2>JS Library</h2>
    </div>
    <div class="span12">
        <a href="http://jquery.com/">jQuery</a> included.
    </div>
</section>

<hr />

<section class="row">
    <div class="span4">
        <h2>Template Engine</h2>
    </div>
    <div class="span12">
        Amon2 uses Text::Xslate(TTerse) as a primary template engine.<br />
        But you can use any template engine easily.
    </div>
</section>

<hr />

<section class="row">
    <div class="span4">
        <h2>O/R Mapper?</h2>
    </div>
    <div class="span12">
        There is no O/R Mapper support. But I recommend to use Teng.<br />
        You can integrate Teng very easily.<br />
        See <a href="http://amon.64p.org/database.html#teng">This page</a> for more details.
    </div>
</section>

<hr />

<section class="row">
    <div class="span16">
        <h1>Documents?</h1>
        <p>Complete docs are available on <a href="http://amon.64p.org/">amon.64p.org</a></p>
        <p>And there is module specific docs on <a href="https://metacpan.org/release/Amon2">CPAN</a></p>
    </div>
</section>

[% END %]
...

    $self->write_file('tmpl/include/layout.tt', <<'...');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<%= $dist %>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <% $tags %>
    <link href="[% uri_for('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% uri_for('/static/js/main.js') %]" rel="stylesheet" type="text/css" media="screen" />
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="topbar-wrapper" style="z-index: 5;">
        <div class="topbar" data-dropdown="dropdown">
            <div class="topbar-inner">
                <div class="container">
                <h3><a href="#"><% $dist %></a></h3>
                <ul class="nav">
                    <li class="active"><a href="#">Home</a></li>
                    <li><a href="#">Link</a></li>
                    <li><a href="#">Link</a></li>
                    <li><a href="#">Link</a></li>
                    <li class="dropdown">
                    <a href="#" class="dropdown-toggle">Dropdown</a>
                    <ul class="dropdown-menu">
                        <li><a href="#">Secondary link</a></li>
                        <li><a href="#">Something else here</a></li>
                        <li class="divider"></li>
                        <li><a href="#">Another link</a></li>
                    </ul>
                    </li>
                </ul>
                <form class="pull-left" action="">
                    <input type="text" placeholder="Search">
                </form>
                <ul class="nav secondary-nav">
                    <li class="dropdown">
                    <a href="#" class="dropdown-toggle">Dropdown</a>
                    <ul class="dropdown-menu">
                        <li><a href="#">Secondary link</a></li>
                        <li><a href="#">Something else here</a></li>
                        <li class="divider"></li>
                        <li><a href="#">Another link</a></li>
                    </ul>
                    </li>
                </ul>
                </div>
            </div><!-- /topbar-inner -->
        </div><!-- /topbar -->
    </div>
    <div class="container">
        <div id="main">
            [% content %]
        </div>
    </div>
    <footer class="footer">
        Powered by <a href="http://amon.64p.org/">Amon2</a>
    </footer>
</body>
</html>
...

    $self->write_file('static/robots.txt', '');

    $self->write_file('static/js/main.js', <<'...');
$(function () {
    $('#topbar').dropdown();
})();
...

    $self->write_file('static/css/main.css', <<'...');
body {
    margin-top: 50px;
}

header {
    height: 50px;
    font-size: 36px;
    padding: 2px;
    text-align: center; }
    header a {
        color: black;
        font-weight: bold;
        text-decoration: none; }

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

    $self->write_file("t/00_compile.t", <<'...');
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
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
inc/
MANIFEST
*.bak
*.old
nytprof.out
nytprof/
development.db
test.db
blib/
pm_to_blib
META.json
META.yml
MYMETA.json
MYMETA.yml
...

    $self->write_file('t/03_assets.t', <<'...');
use strict;
use warnings;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'app.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        for my $fname (qw(static/bootstrap/bootstrap.min.css robots.txt)) {
            my $req = HTTP::Request->new(GET => "http://localhost/$fname");
            my $res = $cb->($req);
            is($res->code, 200, $fname) or diag $res->content;
        }
    };

done_testing;
...

    $self->write_file('.proverc', <<'...');
-l
...

    for my $status (qw/404 500 502 503 504/) {
        $self->write_status_file("static/$status.html", $status);
    }
}

sub write_status_file {
    my ($self, $fname, $status) = @_;

    local $self->{status}         = $status;
    local $self->{status_message} = status_message($status);
 
    $self->write_file($fname, <<'...');
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

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Basic - Basic flavor for Amon2

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Basic MyApp

=head1 DESCRIPTION

This is a basic flavor for Amon2. This is a default flavor.

=head1 AUTHOR

Tokuhiro Matsuno
