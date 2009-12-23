use strict;
use warnings;
use Test::More;
use lib 't/300_misc/lib/';
use MyApp::Config;

isa_ok 'MyApp::Config', "Class::Singleton";
my $config = MyApp::Config->instance;
is ref($config), 'HASH', 'return value is hashref';
is $config->{'M::DB'}->{'dsn'}, 'dbi:SQLite:';
is $config->{'common_thing'}, 'yes';
done_testing;
