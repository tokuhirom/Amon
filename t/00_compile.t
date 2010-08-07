use strict;
use warnings;
use Test::More;

use_ok("Amon2::Web::Response");
use_ok("Amon2::Web::Request");

use lib 't/apps/SampleApp/lib';

package SampleApp;
use Test::More;
use_ok("Amon2", view_class => 'Text::MicroTemplate::File');

done_testing;
