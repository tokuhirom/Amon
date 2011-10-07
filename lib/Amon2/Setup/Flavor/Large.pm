use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Large;
use parent qw(Amon2::Setup::Flavor::Basic);
use File::Path ();
use File::Copy::Recursive qw(rmove rcopy);

sub run {
    my $self = shift;

    $self->SUPER::run();

    # restructure static dir
    rmove('static', 'xxx') or die "$!";
    $self->mkpath('static');
    rmove('xxx', 'static/web') or die "$!";
    rcopy('static/web', 'static/admin') or die "$!";

    # restructure tmpl dir
    rmove('tmpl/', 'yyy') or die "$!";
    $self->mkpath('tmpl');
    rmove('yyy', 'tmpl/web') or die "$!";
    rcopy('tmpl/web', 'tmpl/admin') or die "$!";

    $self->write_file('app.psgi', <<'...', {header => $self->psgi_header});
<% $header %>
use <% $module %>::Web;
use Plack::App::File;
use Plack::Util;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static', 'web');
    enable 'Plack::Middleware::ReverseProxy';

    mount '/admin/' => Plack::Util::load_psgi('admin.psgi');
    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, 'static', 'web'));
    mount '/' => <% $module %>::Web->to_app();
};
...

    $self->write_file('admin.psgi', <<'...', {header => $self->psgi_header});
<% $header %>
use <% $module %>::Admin;
use Plack::App::File;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
builder {
    enable 'Plack::Middleware::Auth::Basic',
        authenticator => sub { $_[0] eq 'admin' && $_[1] eq 'admin' };
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static', 'adin');
    enable 'Plack::Middleware::ReverseProxy';

    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, 'static', 'admin'));
    mount '/' => <% $module %>::Admin->to_app();
};
...

    for my $moniker (qw(Web Admin)) {
        $self->write_file("lib/<<PATH>>/${moniker}.pm", <<'...', { xslate => $self->create_view(tmpl_path => 'tmpl/' . lc($moniker)), moniker => $moniker });
package <% $module %>::<% $moniker %>;
use strict;
use warnings;
use utf8;
use parent qw(<% $module %> Amon2::Web);
use File::Spec;

# dispatcher
use <% $module %>::<% $moniker %>::Dispatcher;
sub dispatch {
    return <% $module %>::<% $moniker %>::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

<% $xslate %>

# load plugins
use File::Path qw(mkpath);
use HTTP::Session::Store::File;
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::NoCache', # do not cache the dynamic content by default
    'Web::CSRFDefender',
    'Web::HTTPSession' => do {
        my $session_dir = File::Spec->catdir(File::Spec->tmpdir(), '<% $path %>');
        mkpath($session_dir);
        +{
            state => 'Cookie',
            store => HTTP::Session::Store::File->new(
                dir => $session_dir
            ),
        }
    },
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);

1;
...
        $self->write_file("lib/<<PATH>>/$moniker/Dispatcher.pm", <<'...', {moniker => $moniker});
package <% $module %>::<% $moniker %>::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::RouterSimple;

use Module::Find;
Module::Find::useall('<% $module %>::<% $moniker %>::C');

connect '/' => {controller => 'Root', action => 'index' };

1;
...

        $self->write_file("lib/<<PATH>>/$moniker/C/Root.pm", <<'...', {moniker => $moniker});
package <% $module %>::<% $moniker %>::C::Root;
use strict;
use warnings;
use utf8;

sub index {
    my ($class, $c) = @_;
    $c->render('index.tt');
}

1;
...
    }

    $self->write_file('tmpl/admin/index.tt', <<'...');
[% WRAPPER 'include/layout.tt' %]

<div class="section">
    <h1>This is a <% $dist %>'s admin site</h1>
</div>

[% END %]
...

    $self->write_file('tmpl/admin/include/layout.tt', <<'...');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<%= $dist %>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <link href="[% static_file('../static/bootstrap/bootstrap.min.css') %]" rel="stylesheet" type="text/css" />
    <script src="[% static_file('../static/js/jquery-1.6.4.min.js') %]"></script>
    <link href="[% static_file('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <script src="[% static_file('/static/js/main.js') %]"></script>
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="topbar-wrapper" style="z-index: 5;">
        <div class="topbar">
            <div class="topbar-inner">
                <div class="container">
                <h3><a href="#"><% $dist %></a></h3>
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
...

    $self->write_file('tmpl/admin/include/sidebar.tt', <<'...');
<ul>
    <li><a href="[% uri_for('/') %]">Home</a></li>
</ul>
...

    $self->write_file("t/00_compile.t", <<'...');
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
    <% $module %>::Web::Dispatcher
    <% $module %>::Web::C::Root
    <% $module %>::Admin
    <% $module %>::Admin::Dispatcher
    <% $module %>::Admin::C::Root
);

done_testing;
...

    $self->write_file('t/04_admin.t', <<'...');
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

        # 401
        {
            my $req = HTTP::Request->new(GET => "http://localhost/admin/");
            my $res = $cb->($req);
            is($res->code, 401, 'basic auth');
        }

        # 200
        {
            my $req = HTTP::Request->new(GET => "http://localhost/admin/");
            $req->authorization_basic('admin', 'admin');
            my $res = $cb->($req);
            is($res->code, 200, 'basic auth');
            like($res->content, qr{admin});
        }
    };

my $admin = Plack::Util::load_psgi 'admin.psgi';
test_psgi
    app => $admin,
    client => sub {
        my $cb = shift;

        # 401
        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            my $res = $cb->($req);
            is($res->code, 401, 'basic auth');
        }

        # 200
        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            $req->authorization_basic('admin', 'admin');
            my $res = $cb->($req);
            is($res->code, 200, 'basic auth');
            like($res->content, qr{admin});
        }
    };

done_testing;
...
}

1;

