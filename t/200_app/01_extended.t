use strict;
use warnings;
use t::Util;
use Test::Requires 'HTTP::MobileAgent', 'HTTP::Session', 'Text::MicroTemplate::Extended', 'Log::Dispatch';

$ENV{PLACK_ENV} = 'development';

run_app_test('Extended');
