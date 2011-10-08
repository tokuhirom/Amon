use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;
use t::Util;

test_flavor(sub {
    ok(-f 'Makefile.PL', 'Makefile.PL');
	like(slurp('Makefile.PL'), qr{Amon2::Plugin::Web::HTTPSession});
    ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
    ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', 'lib/My/App.pm' or die;
            local $/; <$fh>;
        };
    };
    is( scalar( my @files = glob('static/js/jquery-*.js') ), 1 );
}, 'Basic');

done_testing;

