use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'File::Which', 'File::Temp', 'File::pushd', 'LWP::UserAgent';
use File::Temp;
use Amon2::Setup::Flavor::Minimum;
use Amon2::Setup::Flavor::Basic;
use Amon2::Setup::Flavor::Large;
use Test::TCP;
use File::Spec::Functions;
use t::Util qw(slurp);

my $cpanm   = which('cpanm');
my $minil   = which('minil');
my $git     = which('git');
my $sqlite3 = which('sqlite3');
plan skip_all => 'Missing cpanm' unless $cpanm;
plan skip_all => 'Missing minil' unless $minil;
plan skip_all => 'Missing git'   unless $git;
plan skip_all => 'Missing sqlite3'   unless $sqlite3;
plan skip_all => 'AUTHOR_TESTING and TRAVIS only.' unless $ENV{AUTHOR_TESTING} || $ENV{TRAVIS};

run_tests('Amon2::Setup::Flavor::Large', 'my-app-admin-server');
run_tests('Amon2::Setup::Flavor::Large', 'my-app-web-server');
run_tests('Amon2::Setup::Flavor::Minimum', 'my-app-server');
run_tests('Amon2::Setup::Flavor::Basic', 'my-app-server');

done_testing;

sub run_tests {
    my ($flavor_class, $script) = @_;

    subtest "$flavor_class -> $script" => sub {
        my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );
        my $libdir = File::Temp::tempdir( CLEANUP => 1 );
        my $dbdir = File::Temp::tempdir( CLEANUP => 1 );
        my $workdir = catdir($tmpdir, 'My-App');
        {
            mkdir $workdir;
            my $guard = pushd($workdir);

            my $flavor = $flavor_class->new(module => 'My::App');
            $flavor->run;
            is system($git, 'init'), 0;
            is system($git, 'add', '.'), 0;
            is system($git, 'commit', '-m', 'initial import'), 0;
            is system($^X, '--', $minil, 'migrate'), 0;
            ok -f 'META.json', 'Generated META.json';
        }
        my @opts = ();
        # my @opts = ('--verbose', '--no-interactive');
        is system($^X, '--', $cpanm, @opts, '--installdeps', '-l', $libdir, $workdir), 0;
        is system($^X, '--', $cpanm, @opts, '-l', $libdir, $workdir), 0;

        if (-f "$workdir/sql/sqlite.sql") {
            diag "Installing sql";
            is system("$sqlite3 $dbdir/test.db < $workdir/sql/sqlite.sql"), 0;
        }

        my $conf = File::Temp->new();
        print {$conf} <<"...";
use File::Spec;
use File::Basename qw(dirname);
+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbdir/test.db", '', '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

        note slurp("$libdir/bin/${script}");

        test_tcp(
            client => sub {
                my $port = shift;
                my $ua = LWP::UserAgent->new();
                $ua->credentials( "127.0.0.1:${port}", 'restricted area', 'admin', 'admin');
                my $res = $ua->get("http://127.0.0.1:${port}/");
                is($res->code, 200);
            },
            server => sub {
                my $port = shift;
                exec $^X, "-Mlib=$libdir/lib/perl5/", '--', "$libdir/bin/${script}", '-p', $port, '-c', $conf;
                die;
            },
        );
    };
}

