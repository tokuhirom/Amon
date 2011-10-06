use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Large;

sub parent { 'Basic' }

sub assets { qw(jQuery Bootstrap) }
sub admin_context { 'lib/<<PATH>>/Admin.pm' }

# TODO: basic auth?

1;
__DATA__

@@ app.psgi
: cascade "!"
: before app -> {
require <: $module :>::Admin;
: }
: around to_app -> {
    builder {
        mount '/admin/' => builder {
            enable 'Auth::Basic', authenticator => sub {
                my ($id, $pw) = @_;
                return $id eq 'admin' && $pw eq 'admin';
            };
            <: $module :>::Admin->to_app();
        };
        mount '/'       => <: $module :>::Web->to_app();
    };
: }

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

my $app = Plack::Util::load_psgi('app.psgi')
    or die "Cannot load app";
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

done_testing;

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
    <: $tags :>
    <link href="[% static_file('/static/admin/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% static_file('/static/admin/js/main.js') %]" rel="stylesheet" type="text/css" media="screen" />
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="topbar-wrapper" style="z-index: 5;">
        <div class="topbar" data-dropdown="dropdown">
            <div class="topbar-inner">
                <div class="container">
                <h3><a href="#"><: $dist :></a></h3>
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

@@ tmpl/admin/index.tt
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

@@ tmpl/include/admin/css/main.css

@@ tmpl/include/admin/css/main.js
$(function () {
    $('#topbar').dropdown();
})();

