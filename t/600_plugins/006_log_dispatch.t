use strict;
use warnings;
use Test::More;
use Test::Requires 'Log::Dispatch';

BEGIN {
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use parent qw/Amon2/;
    __PACKAGE__->load_plugins('LogDispatch' => {
        outputs => [ ['Null', 'min_level' => 'debug'] ]
    });
}


my $c = MyApp->new();
$c->log->emerg("HELP ME");
isa_ok $c->log(), 'Log::Dispatch';
done_testing;

