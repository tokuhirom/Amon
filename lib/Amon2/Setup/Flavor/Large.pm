use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Large;

sub parent { 'Basic' }

sub assets { qw(jQuery Bootstrap) }

1;
__DATA__

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
