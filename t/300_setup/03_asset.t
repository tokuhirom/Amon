use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '../..'),
    File::Spec->catdir($FindBin::Bin, '../../lib/');
use t::Util;

use Amon2::Setup::Asset::XSRFTokenJS;
use Amon2::Setup::Flavor;

my $orig_cwd = Cwd::getcwd();

my $tmpdir = tempdir(CLEANUP => 1);

chdir $tmpdir;

my $flavor = Amon2::Setup::Flavor->new(module => 'Foo');
$flavor->load_asset('XSRFTokenJS');
$flavor->write_asset('XSRFTokenJS');
ok(-f 'static/js/xsrf-token.js');

like($flavor->{tags}, qr/xsrf-token\.js/);

chdir $orig_cwd;
undef $tmpdir;

done_testing;
