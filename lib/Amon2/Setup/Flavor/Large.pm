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
        my $session_dir = File::Spec->catdir(File::Spec->tmpdir(), '<: $path :>');
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
    <h1>This is a <: $dist :>'s admin site</h1>
</div>

[% END %]
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

done_testing;
...
}

1;

