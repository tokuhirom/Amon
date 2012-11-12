package Extended::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::RouterSimple;

connect '/'        => 'Root#index';
connect '/die'     => 'Root#die';
connect '/session' => 'Root#session';

1;
