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
            enable 'Plack::Middleware::Static',
                path => qr{^(?:/admin/static/)},
                root => File::Spec->catdir(dirname(__FILE__));
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
    <link href="[% static_file('/static/bootstrap/bootstrap.min.css') | replace('^/admin', '') %]" rel="stylesheet" type="text/css" />
    <script src="[% static_file('/static/js/jquery-1.6.4.min.js') | replace('^/admin', '') %]"></script>
    <link href="[% static_file('/static/admin/css/main.css') | replace('^/admin', '') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% static_file('/static/admin/js/main.js') | replace('^/admin', '') %]" rel="stylesheet" type="text/css" media="screen" />
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
    <h1>This is a <: $module :>'s admin site</h1>
</div>

[% END %]

@@ static/admin/css/main.css
body {
    margin-top: 50px;
}

@@ tmpl/include/admin/css/main.js
$(function () {
    $('#topbar').dropdown();
})();

