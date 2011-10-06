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
        mount '/admin/' => <: $module :>::Admin->to_app();
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
: include "#xslate"
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
        my $req = HTTP::Request->new(GET => 'http://localhost/admin/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
