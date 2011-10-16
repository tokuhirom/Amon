use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Large;
use parent qw(Amon2::Setup::Flavor::Basic);
use File::Path ();
use File::Copy::Recursive qw(rmove rcopy);

sub create_makefile_pl {
    my ($self, $prereq_pm) = @_;

    $self->SUPER::create_makefile_pl(
        +{
            %{ $prereq_pm || {} },
            'String::CamelCase' => '0.02',
			'Mouse'             => '0.95', # Mouse::Util
        },
    );
}

sub run {
    my $self = shift;

    $self->SUPER::run();

    # restructure static dir
    rmove('static', 'xxx') or die "$!";
    $self->mkpath('static');
    rmove('xxx', 'static/pc') or die "$!";
    rcopy('static/pc', 'static/admin') or die "$!";

    # restructure tmpl dir
    rmove('tmpl/', 'yyy') or die "$!";
    $self->mkpath('tmpl');
    rmove('yyy', 'tmpl/pc') or die "$!";
    rcopy('tmpl/pc', 'tmpl/admin') or die "$!";

    unlink 'static/admin/css/main.css' or die $!;

    $self->write_file('pc.psgi', <<'...', {header => $self->psgi_header});
<% $header %>
use <% $module %>::PC;
use Plack::App::File;
use Plack::Util;
use Plack::Session::Store::DBI;
use DBI;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
my $db_config = <% $module %>->config->{DBI} || die "Missing configuration for DBI";
{
    my $c = <% $module %>->new();
    $c->setup_schema();
}
builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static', 'pc');
    enable 'Plack::Middleware::ReverseProxy';
	enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                DBI->connect( @$db_config )
                    or die $DBI::errstr;
            }
        );

    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, 'static', 'pc'));
    mount '/' => <% $module %>::PC->to_app();
};
...

    $self->write_file('app.psgi', <<'...', {header => $self->psgi_header});
<% $header %>
use <% $module %>::PC;
use Plack::Util;
use Plack::Builder;

builder {
    mount '/admin/' => Plack::Util::load_psgi('admin.psgi');
    mount '/' => Plack::Util::load_psgi('pc.psgi');
};
...

    $self->write_file('admin.psgi', <<'...', {header => $self->psgi_header});
<% $header %>
use <% $module %>::Admin;
use Plack::App::File;
use Plack::Session::Store::DBI;
use DBI;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
my $db_config = <% $module %>->config->{DBI} || die "Missing configuration for DBI";
{
    my $c = <% $module %>->new();
    $c->setup_schema();
}
builder {
    enable 'Plack::Middleware::Auth::Basic',
        authenticator => sub { $_[0] eq 'admin' && $_[1] eq 'admin' };
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static', 'adin');
    enable 'Plack::Middleware::ReverseProxy';
	enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                DBI->connect( @$db_config )
                    or die $DBI::errstr;
            }
        );

    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, 'static', 'admin'));
    mount '/' => <% $module %>::Admin->to_app();
};
...

    for my $moniker (qw(PC Admin)) {
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
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::NoCache', # do not cache the dynamic content by default
    'Web::CSRFDefender',
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
        $res->header( 'X-Frame-Options' => 'DENY' );
    },
);

1;
...
        $self->write_file("lib/<<PATH>>/$moniker/Dispatcher.pm", <<'...', {moniker => $moniker});
package <% $module %>::<% $moniker %>::Dispatcher;
use strict;
use warnings;
use utf8;
use Router::Simple::Declare;
use Mouse::Util qw(get_code_package);
use Module::Find ();
use String::CamelCase qw(decamelize);

# define roots here.
my $router = router {
	# connect '/' => {controller => 'Root', action => 'index' };
};

my @controllers = Module::Find::useall('<% $module %>::<% $moniker %>::C');
{
    no strict 'refs';
    for my $controller (@controllers) {
        my $p0 = $controller;
        $p0 =~ s/^<% $module %>::<% $moniker %>::C:://;
        my $p1 = $p0 eq 'Root' ? '' : decamelize($p0) . '/';

        for my $method (sort keys %{"${controller}::"}) {
            next if $method =~ /(?:^_|^BEGIN$|^import$)/;
            my $code = *{"${controller}::${method}"}{CODE};
            next unless $code;
            next if get_code_package($code) ne $controller;
			my $p2 = $method eq 'index' ? '' : $method;
			my $path = "/$p1$p2";
            $router->connect($path => {
                controller => $p0,
                action     => $method,
            });
            print STDERR "map: $path => ${p0}::${method}\n" unless $ENV{HARNESS_ACTIVE};
        }
    }
}

sub dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $router->match($req->env)) {
        my $action = $p->{action};
        $c->{args} = $p;
        "@{[ ref Amon2->context ]}::C::$p->{controller}"->$action($c, $p);
    } else {
        $c->res_404();
    }
}

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

	$self->write_file("lib/<<PATH>>/PC/C/Account.pm", <<'...');
package <% $module %>::PC::C::Account;
use strict;
use warnings;
use utf8;

sub logout {
    my ($class, $c) = @_;
	$c->session->expire();
	$c->redirect('/');
}

1;
...

    $self->write_file('tmpl/admin/index.tt', <<'...');
[% WRAPPER 'include/layout.tt' %]

<section>
    <h1>This is a <% $dist %>'s admin site</h1>
</section>

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
    <link href="[% static_file('/static/css/admin.css') %]" rel="stylesheet" type="text/css" media="screen" />
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
    <div class="container-fluid">
        <div class="sidebar">
                [% INCLUDE "include/sidebar.tt" %]
		</div>
		<div class="content">
			[% content %]
		</div>
    </div>
	<footer class="footer">
		Powered by <a href="http://amon.64p.org/">Amon2</a>
	</footer>
</body>
</html>
...

    $self->write_file('static/admin/css/admin.css', <<'...', {color1 => '#117711', color2 => '#119911'});
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

.topbar-inner,.topbar .fill{
    background-color:<% color1 %>;
    background-repeat:repeat-x;
    background-image:-khtml-gradient(linear, left top, left bottom, from(<% color2 %>), to(<% color1 %>));
    background-image:-moz-linear-gradient(top, <% color2 %>, <% color1 %>);
    background-image:-ms-linear-gradient(top, <% color2 %>, <% color1 %>);
    background-image:-webkit-gradient(linear, left top, left bottom, color-stop(0%, <% color2 %>), color-stop(100%, <% color1 %>));
    background-image:-webkit-linear-gradient(top, <% color2 %>, <% color1 %>);
    background-image:-o-linear-gradient(top, <% color2 %>, <% color1 %>);
    background-image:linear-gradient(top, <% color2 %>, <% color1 %>);
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='<% color2 %>', endColorstr='<% color1 %>', GradientType=0);
    -webkit-box-shadow:0 1px 3px rgba(0, 0, 0, 0.25),inset 0 -1px 0 rgba(0, 0, 0, 0.1);
    -moz-box-shadow:0 1px 3px rgba(0, 0, 0, 0.25),inset 0 -1px 0 rgba(0, 0, 0, 0.1);
    box-shadow:0 1px 3px rgba(0, 0, 0, 0.25),inset 0 -1px 0 rgba(0, 0, 0, 0.1);
}
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
    <% $module %>::PC
    <% $module %>::PC::Dispatcher
    <% $module %>::PC::C::Root
    <% $module %>::PC::C::Account
    <% $module %>::Admin
    <% $module %>::Admin::Dispatcher
    <% $module %>::Admin::C::Root
);

done_testing;
...

    $self->write_file('t/04_admin.t', <<'...');
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

