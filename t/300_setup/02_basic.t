use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;
use t::Util;
use Test::Requires +{
	'Amon2::DBI'                      => '0.05',
	'DBD::SQLite'                     => '1.33',
};

test_flavor(sub {
    ok(-f 'Makefile.PL', 'Makefile.PL');
	like(slurp('Makefile.PL'), qr{Plack::Session});
	for my $env (qw(development deployment test)) {
		ok(-f "config/${env}.pl");
		my $conf = do "config/${env}.pl";
		is(ref($conf), 'HASH');
	}
    ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
    ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', 'lib/My/App.pm' or die;
            local $/; <$fh>;
        };
    };
    is( scalar( my @files = glob('static/js/jquery-*.js') ), 1 );
	like(slurp('t/02_mech.t'), qr{account/logout});
	like(slurp('Makefile.PL'), qr{'Amon2::DBI'\s+=>\s*'[0-9.]+'});
}, 'Basic');

done_testing;

