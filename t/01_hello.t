use strict;
use warnings;
use File::Temp qw/tempdir/;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use Plack::Util;
use Plack::Test;
use Cwd;
use Test::More;

my $cwd = Cwd::cwd;

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die $!;
unshift @INC, File::Spec->catfile($dir, 'Hello', 'lib');

my $setup = File::Spec->catfile($FindBin::Bin, '..', 'script', 'amon-setup.pl');
my $libdir = File::Spec->catfile($FindBin::Bin, '..', 'lib');
!system $^X, '-I', $libdir, $setup, 'Hello' or die $!;
chdir 'Hello' or die $!;

my $app = do 'Hello.psgi' or die "Cannot compile .psgi: $@";
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        like $res->content, qr/hello, Amon world!/;
    };

chdir $cwd;
done_testing;

