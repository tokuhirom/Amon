use strict;
use warnings;
use Test::More;

BEGIN {$INC{'MyApp/ConfigLoader.pm'} = __FILE__; }

{
    package MyApp;
    use Amon -base => (
        config_loader_class => 'MyApp::ConfigLoader',
    );
}

{
    package MyApp::ConfigLoader;
    sub load {
        +{"YE" => "AH"};
    }
}

my $app = MyApp->new();
is $app->config->{"YE"} => "AH";

done_testing;
