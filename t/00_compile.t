use strict;
use warnings;
use Test::More;

use_ok("Amon::Web::Response");
use_ok("Amon::Web::Request");

use lib 't/apps/SampleApp/lib';

package SampleApp;
use Test::More;
use_ok("Amon", view_class => 'MT');

done_testing;
