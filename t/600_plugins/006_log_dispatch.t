use strict;
use warnings;
use Test::More;
use Test::Requires 'Log::Dispatch';

BEGIN {
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use Amon2 -base;
    __PACKAGE__->load_plugins('LogDispatch' => {
        outputs => [ ['Null', 'min_level' => 'debug'] ]
    });
}


my $c = MyApp->new();
$c->logger->emerg("HELP ME");
isa_ok $c->logger, 'Log::Dispatch';
done_testing;

