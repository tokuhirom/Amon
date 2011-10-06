use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Large;

sub is_standalone { 1 }

sub parent { 'Minimum' }

sub assets { qw(jQuery Bootstrap) }

sub plugins {
    qw(
        Web::HTTPSession
        Web::JSON
        Web::CSRFDefender
        Web::FillInFormLite
        Web::NoCache
    );
}

sub config_development_path { 'config/development.pl' }
sub config_deployment_path  { 'config/deployment.pl' }
sub config_test_path        { 'config/test.pl' }
sub admin_context           { 'lib/<<PATH>>/Admin.pm' }

sub load_assets {
    my ($class, $setup, $assets) = @_;
    for my $asset (@$assets) {
        my $files = $asset->files;
        while (my ($fname, $data) = each %$files) {
            $fname =~ s!^static/!static/web/!;
            $setup->write_file_raw($fname, $data);
            $fname =~ s!^static/web/!static/admin/!;
            $setup->write_file_raw($fname, $data);
        }
    }
}

1;
__DATA__

@@ app.psgi
: include "#app.psgi-header"

use Plack::Builder;
use Plack::Util;

require <: $module :>::Web;

: block to_app -> {
my $basedir = File::Spec->rel2abs(dirname(__FILE__));

builder {
    my $admin = Plack::Util::load_psgi('admin.psgi')
                    or die "Cannot load admin.psgi: $@";
    mount '/admin/' => $admin;

    mount '/' => builder {
        #mount '/static/' => Plack::App::File->new(root => "$basedir/static/web/");
: block middlewares -> {
        enable 'Plack::Middleware::Static',
            path => qr{^(?:/robots\.txt|/favicon.ico)$},
            root => File::Spec->catdir(dirname(__FILE__), 'static', 'web');
        enable 'Plack::Middleware::ReverseProxy';
: }
        mount '/static' => Plack::App::File->new(root => "$basedir/static/web/");
        mount '/' => <: $module :>::Web->to_app();
    };
};
: }

@@ admin.psgi
: include "#app.psgi-header"

use Plack::Builder;
use Plack::App::File;
require <: $module :>::Admin;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));

builder {
    enable 'Auth::Basic', authenticator => sub {
        my ($id, $pw) = @_;
        return $id eq 'admin' && $pw eq 'admin';
    };
    mount '/static' => Plack::App::File->new(
        root => File::Spec->catdir($basedir, 'static', 'admin')
    );
    mount '/' => <: $module :>::Admin->to_app();
};

@@ lib/<<PATH>>.pm
: cascade '!';
: around load_config -> { }

@@ lib/<<PATH>>/Admin.pm
package <: $module :>::Admin;
use strict;
use warnings;
use utf8;
use parent qw(<: $module :> Amon2::Web);
use File::Spec;

: block prepare -> {
# load all controller classes
use Module::Find ();
Module::Find::useall("<: $module :>::Admin::C");
: }

: block dispatch -> {
# dispatcher
use <: $module :>::Web::Dispatcher;
sub dispatch {
    return <: $module :>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}
: }

: block create_view -> {
: include "#xslate" { template_path => "'tmpl', 'admin'" };
: }

: block load_plugins -> { }

: block triggers -> {
# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);
: }

1;

@@ lib/<<PATH>>/Admin/Dispatcher.pm
package <: $module :>::Admin::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::RouterSimple;

connect '/' => {controller => 'Root', action => 'index' };

1;
@@ lib/<<PATH>>/Admin/C/Root.pm
package <: $module :>::Admin::C::Root;
use strict;
use warnings;
use utf8;

sub index {
    my ($class, $c) = @_;
    $c->render('index.tt');
}

1;

@@ lib/<<PATH>>/Web.pm
: cascade "!";

: after prepare -> {
# load all controller classes
use Module::Find ();
Module::Find::useall("<: $module :>::Web::C");
: }

: around dispatch -> {
# dispatcher
use <: $module :>::Web::Dispatcher;
sub dispatch {
    return <: $module :>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}
: }

: around create_view -> {
: include "#xslate" { template_path => "'tmpl', 'web'" };
: }

@@ lib/<<PATH>>/Web/Dispatcher.pm
package <: $module :>::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::RouterSimple;

connect '/' => {controller => 'Root', action => 'index' };

1;
@@ lib/<<PATH>>/Web/C/Root.pm
package <: $module :>::Web::C::Root;
use strict;
use warnings;
use utf8;

sub index {
    my ($class, $c) = @_;
    $c->render('index.tt');
}
1;

@@ t/04_admin.t
use strict;
use warnings;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

subtest 'app.psgi' => sub {
    my $app = Plack::Util::load_psgi('app.psgi')
        or die "Cannot load app: $@";
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => 'http://admin:admin@localhost/admin/');
            $req->headers->authorization_basic('admin', 'admin');
            my $res = $cb->($req);
            is $res->code, 200;
            diag $res->content if $res->code != 200;
        };
};

subtest 'admin.psgi' => sub {
    my $app = Plack::Util::load_psgi('admin.psgi')
        or die "Cannot load app: $@";
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            $req->headers->authorization_basic('admin', 'admin');
            my $res = $cb->($req);
            is $res->code, 200;
            diag $res->content if $res->code != 200;
        };
};

done_testing;

@@ tmpl/admin/include/sidebar.tt
<ul>
    <li><a href="[% uri_for('/') %]">Home</a></li>
</ul>

@@ tmpl/admin/include/layout.tt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<:= $dist :>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <link href="[% static_file('../static/bootstrap/bootstrap.min.css') %]" rel="stylesheet" type="text/css" />
    <script src="[% static_file('../static/js/jquery-1.6.4.min.js') %]"></script>
    <link href="[% static_file('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% static_file('/static/js/main.js') %]" rel="stylesheet" type="text/css" media="screen" />
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="topbar-wrapper" style="z-index: 5;">
        <div class="topbar">
            <div class="topbar-inner">
                <div class="container">
                <h3><a href="#"><: $dist :></a></h3>
                </div>
            </div><!-- /topbar-inner -->
        </div><!-- /topbar -->
    </div>
    <div class="container clearfix">
        <div class="row">
            <div class="span4">
                [% INCLUDE "include/sidebar.tt" %]
            </div>
            <div class="span12">
                [% content %]
            </div>
        </div>
        <footer class="footer">
            Powered by <a href="http://amon.64p.org/">Amon2</a>
        </footer>
    </div>
</body>
</html>

@@ tmpl/admin/index.tt
[% WRAPPER 'include/layout.tt' %]

<div class="section">
    <h1>This is a <: $dist :>'s admin site</h1>
</div>

[% END %]

@@ static/admin/js/main.js

@@ static/admin/css/main.css
body {
    margin-top: 50px;
}

@@ config/development.pl
+{
: block config_development -> {
: }
};

@@ config/deployment.pl
+{
: block config_deployment -> {
: }
};

@@ config/test.pl
+{
: block config_test -> {
: }
};

@@ sql/my.sql

@@ tmpl/web/index.tt
[% WRAPPER 'include/layout.tt' %]

<div class="row">
    <div class="span10">
        <h1>Hello, Amon2 world!</h1>

        <h2>For benchmarkers...</h2>
        <p>If you want to benchmarking between Plack based web application frameworks, you should use <B>Amon2::Setup::Flavor::Minimum</B> instead.</p>
        <p>You can use it as following one liner:</p>
        <pre>% amon2-setup.pl --flavor Minimum <: $module :></pre>
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

@@ tmpl/web/include/layout.tt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<:= $dist :>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <: $tags :>
    <link href="[% static_file('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% static_file('/static/js/main.js') %]" rel="stylesheet" type="text/css" media="screen" />
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="topbar-wrapper" style="z-index: 5;">
        <div class="topbar">
            <div class="topbar-inner">
                <div class="container">
                <h3><a href="#"><: $dist :></a></h3>
                <ul class="nav">
                    <li class="active"><a href="#">Home</a></li>
                    <li><a href="#">Link</a></li>
                    <li><a href="#">Link</a></li>
                    <li><a href="#">Link</a></li>
                </ul>
                <form class="pull-left" action="">
                    <input type="text" placeholder="Search">
                </form>
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

@@ static/web/robots.txt

@@ static/web/js/main.js
$(function () {
    $('#topbar').dropdown();
})();

@@ static/web/css/main.css
body {
    margin-top: 50px;
}

/* smart phones */
@media screen and (max-device-width: 480px) {
}
