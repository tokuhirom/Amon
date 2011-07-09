use strict;
use warnings;
use t::Util;
use Test::Requires 'HTTP::Session', 'Text::MicroTemplate::Extended', 'Amon2::Plugin::LogDispatch', 'Log::Dispatch', 'Tiffany';

$ENV{PLACK_ENV} = 'development';

run_app_test('Extended');
