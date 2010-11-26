use strict;
use warnings;
use t::Util;
use Test::Requires 'HTTP::MobileAgent', 'HTTP::Session', 'Text::MicroTemplate::Extended', 'Log::Dispatch';

run_app_test('Extended');
