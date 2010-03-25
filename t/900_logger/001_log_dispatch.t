use strict;
use warnings;
use Test::Requires 'Log::Dispatch', 'Data::OptList';
use Test::More;
use_ok 'Amon::Logger::LogDispatch';

my $logger = Amon::Logger::LogDispatch->new({
    loggers => [
        'Null' => {
            min_level => 'debug',
        }
    ]
});
$logger->debug("HOGE");
$logger->log('debug', 'yay');

done_testing;
