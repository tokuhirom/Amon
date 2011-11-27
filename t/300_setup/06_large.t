use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use t::TestFlavor;
use Test::Requires {
	'String::CamelCase' => '0.02',
	'Mouse'             => '0.95', # Mouse::Util
	'Amon2::DBI'                      => '0.05',
	'DBD::SQLite'                     => '1.33',
    'Plack::Session'                  => '0.14',
    'Module::Find'                    => '0.10',
    'Test::WWW::Mechanize::PSGI'      => 0,
};

test_flavor(sub {
    ok(!-e 'xxx');
    ok(!-e 'yyy');
    my @files = (<Amon2::*>);
    is(0+@files, 0);

    for my $dir (qw(tmpl/ tmpl/pc tmpl/admin/ static/pc static/admin)) {
        ok(-d $dir, $dir);
    }
	for my $file (qw(Makefile.PL lib/My/App.pm t/Util.pm .proverc tmpl/pc/error.tt tmpl/admin/error.tt)) {
		ok(-f $file, "$file exists");
	}
    for my $f (qw(lib/My/App/Web.pm lib/My/App/Web/ tmpl/index.tt)) {
        ok(!-e $f, "There is no $f");
    }

    for my $type (qw(PC Admin)) {
        open my $pfh, '>', "lib/My/App/$type/C/Error.pm" or die "$type: $!";
        print $pfh sprintf(<<'...', $type);
package My::App::%s::C::Error;
use strict;

sub error {
    my ($class, $c) = @_;
    return $c->show_error('Oops!');
}

1;
...
        close $pfh;
    }

    {
        no warnings 'once';
        local *My::App::setup_schema;
        ok((do 'lib/My/App.pm'), 'lib/My/App.pm is valid') or do {
            diag $@;
            diag do {
                open my $fh, '<', 'lib/My/App.pm' or die;
                local $/; <$fh>;
            };
        };
    }

    my $app = Plack::Util::load_psgi('app.psgi');
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
    {
        my $res = $mech->get('http://localhost/error/error');
        is($res->code, 500);
        like($res->content, qr{An error});
        like($res->content, qr{Oops});
    }
    {
        my $res = $mech->get('http://localhost/admin/error/error');
        is($res->code, 401);
    }
    {
        $mech->credentials('admin', 'admin');
        my $res = $mech->get('http://localhost/admin/error/error');
        is($res->code, 500);
        like($res->content, qr{An error});
        like($res->content, qr{Oops});
    };

    like(slurp('tmpl/pc/include/layout.tt'), qr{jquery}, 'loads jquery');
}, 'Large');

done_testing;

