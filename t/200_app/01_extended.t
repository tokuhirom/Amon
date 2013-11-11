use strict;
use warnings;
use t::Util;
use Test::Requires 'HTTP::MobileAgent', 'HTTP::Session', 'Text::MicroTemplate::Extended', 'Amon2::Plugin::LogDispatch', 'Log::Dispatch', 'Tiffany', 'Amon2::Plugin::Web::MobileAgent', 'Router::Simple', 'Amon2::Plugin::Web::HTTPSession';

$ENV{PLACK_ENV} = 'development';

run_app_test('Extended');
