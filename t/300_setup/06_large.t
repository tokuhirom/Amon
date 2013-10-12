use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use t::TestFlavor;
use Test::Requires {
	'Mouse'             => '0.95', # Mouse::Util
	'Teng'                            => '0.18',
	'DBD::SQLite'                     => '1.33',
    'Plack::Session'                  => '0.14',
    'Module::Find'                    => '0.10',
    'Test::WWW::Mechanize::PSGI'      => 0,
    'Module::Functions'               => '0',
    'HTML::FillInForm::Lite'          => 0,
    'Router::Boom'                    => '0.03',
};

test_flavor(sub {
    ok(!-e 'xxx');
    ok(!-e 'yyy');
    my @files = (<Amon2::*>);
    is(0+@files, 0);

    system('sqlite3 db/test.db < sql/sqlite.sql');
    system('sqlite3 db/development.db < sql/sqlite.sql');

    for my $dir (qw(tmpl/ tmpl/web tmpl/admin/ static/web static/admin)) {
        ok(-d $dir, $dir);
    }
	for my $file (qw(Build.PL lib/My/App.pm t/Util.pm .proverc tmpl/web/error.tx tmpl/admin/error.tx)) {
		ok(-f $file, "$file exists");
	}
    for my $f (qw(lib/My/App/PC.pm lib/My/App/PC/ tmpl/index.tx)) {
        ok(!-e $f, "There is no $f");
    }

    for my $type (qw(web admin)) {
        my $f = "script/my-app-${type}-server";
        my $buff = << "...";
\$SIG{__WARN__} = sub { die 'Warned! ' . shift };
@{[slurp($f)]}
...
        open my $fh, '>', $f;
        print $fh $buff;
        close $fh;
    }

    subtest 'test web' => sub {
        my $app = Plack::Util::load_psgi("script/my-app-web-server");
        my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
        my $res = $mech->get('http://localhost/');
        is($res->code, 200);
    };

    subtest 'admin' => sub {
        my $app = Plack::Util::load_psgi("script/my-app-admin-server");
        my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
        {
            my $res = $mech->get('http://localhost/');
            is($res->code, 401);
        }
        {
            $mech->credentials('admin', 'admin');
            my $res = $mech->get('http://localhost/');
            is($res->code, 200);
        };
    };

    like(slurp('tmpl/web/include/layout.tx'), qr{jquery}, 'loads jquery');
}, 'Large');

done_testing;

