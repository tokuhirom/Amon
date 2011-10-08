use strict;
use warnings;
use utf8;
use Test::More;
use t::TestFlavor;
use Test::Requires {
	'String::CamelCase' => '0.02',
	'Mouse'             => '0.95', # Mouse::Util
	'Amon2::DBI'                      => '0.05',
	'DBD::SQLite'                     => '1.33',
};

test_flavor(sub {
    ok(!-e 'xxx');
    ok(!-e 'yyy');
    my @files = (<Amon2::*>);
    is(0+@files, 0);

    for my $dir (qw(tmpl/ tmpl/web tmpl/admin/)) {
        ok(-d $dir, $dir);
    }
    ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
    ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', 'lib/My/App.pm' or die;
            local $/; <$fh>;
        };
    };
}, 'Large');

done_testing;

