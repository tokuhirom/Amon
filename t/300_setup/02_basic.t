use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '../..');
use t::TestFlavor;
use t::Util;
use Test::Requires +{
	'Teng'                            => '0.18',
	'DBD::SQLite'                     => '1.33',
    'DBI'                             => 0,
    'Module::Functions'               => '0',
    'HTML::FillInForm::Lite'          => 0,
    'Plack::Middleware::ReverseProxy' => 0,
    'Plack::Middleware::Session'      => 0,
    'Plack::Session::Store::File'     => 0,
};

test_flavor(sub {
    ok(-f 'Build.PL', 'Build.PL');
	like(slurp('cpanfile'), qr{Plack::Middleware::Session});
	for my $env (qw(development production test)) {
		ok(-f "./config/${env}.pl");
		my $conf = do "./config/${env}.pl";
		is(ref($conf), 'HASH');
	}
    ok(-f './lib/My/App.pm', 'lib/My/App.pm exists');
    like(slurp('./lib/My/App/Web/Plugin/Session.pm'), qr{sub _validate_xsrf_token});
    like(slurp('./script/my-app-server'), qr{Plack::Session::Store::File}, 'uses file session store');
    ok((do './lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
        diag $@;
        diag do {
            open my $fh, '<', './lib/My/App.pm' or die;
            local $/; <$fh>;
        };
    };
    ok(-f './static/js/xsrf-token.js', 'xsrf-token.js exists');
	like(slurp('./cpanfile'), qr{'Teng'\s*,\s*'[0-9.]+'});
}, 'Basic');

done_testing;
