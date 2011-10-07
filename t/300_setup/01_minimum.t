use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;

test_flavor(sub {
    ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
    ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', 'lib/My/App.pm' or die;
            local $/; <$fh>;
        };
    };
}, 'Minimum');

done_testing;

