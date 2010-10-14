use strict;
use warnings;
use Test::More;
use Test::Requires 'Log::Dispatch';

{
    package MyApp;
    use parent qw/Amon2/;
    sub load_config {
        +{ 'Log::Dispatch' =>
              { outputs => [ [ 'Null', 'min_level' => 'debug' ] ] } };
    }
    __PACKAGE__->load_plugins('LogDispatch');
}


my $c = MyApp->new();
$c->log->emerg("HELP ME");
isa_ok $c->log(), 'Log::Dispatch';
done_testing;

