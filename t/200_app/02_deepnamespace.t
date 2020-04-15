use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '../..');
use t::Util;
use Test::Requires 'Text::MicroTemplate::Extended', 'Tiffany', 'Module::Find';

plan skip_all => "this test requires perl 5.10 or later" if $] < 5.010;

$ENV{PLACK_ENV} = 'development';

run_app_test('DeepNamespace');
