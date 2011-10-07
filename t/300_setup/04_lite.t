use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;

test_flavor(sub {
    ok(-f 'app.psgi', 'app.psgi exists');
    ok((do 'app.psgi'), 'app.psgi is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', 'app.psgi' or die;
            local $/; <$fh>;
        };
    };
}, 'Lite');

done_testing;

