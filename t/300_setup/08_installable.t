use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'File::Which', 'File::Temp', 'File::pushd', 'Furl';
use File::Temp;
use Amon2::Setup::Flavor::Minimum;
use Test::TCP;

my $cpanm = which('cpanm');
plan skip_all => 'Missing cpanm' unless $cpanm;
plan skip_all => 'AUTHOR_TESTING and TRAVIS_CI only.' unless $ENV{AUTHOR_TESTING} || $ENV{TRAVIS};

my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );
my $libdir = File::Temp::tempdir( CLEANUP => 1 );
{
    my $guard = pushd($tmpdir);

    my $flavor = Amon2::Setup::Flavor::Minimum->new(module => 'My::App');
    $flavor->run;
    system("$^X Build.PL");
    system("./Build");
    note `tree .`;
}
is system($^X, '--', $cpanm, '--installdeps', '-l', $libdir, $tmpdir), 0;
is system($^X, '--', $cpanm, '--verbose', '--no-interactive', '-l', $libdir, $tmpdir), 0;
note `tree $libdir`;

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = Furl->new();
        my $res = $ua->get("http://127.0.0.1:${port}/");
        is($res->code, 200);
    },
    server => sub {
        my $port = shift;
        exec $^X, "-Mlib=$libdir/lib/perl5/", "$libdir/bin/my-app-server", '-p', $port;
        die;
    },
);

done_testing;

