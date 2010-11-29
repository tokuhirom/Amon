package Hello::Web::Dispatcher;
use strict;
use warnings;

use Amon2::Web::Dispatcher::RouterSimple;

connect '/'              => 'Root#index';
connect '/post'          => 'Root#post';


1;
