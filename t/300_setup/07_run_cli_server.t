use strict;
use warnings;
use utf8;
use Test::More;
use Test::TCP;
use Amon2::Setup::Flavor::Minimum;
use File::Temp;
use Test::Requires 'File::pushd', 'Furl', 'Module::Functions', 'Starlet';

my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );
{
    my $guard = pushd($tmpdir);

    my $flavor = Amon2::Setup::Flavor::Minimum->new(module => 'My::App');
    $flavor->run;

    note `tree .`;
    ok -f 'script/my-app-server';
    test_tcp(
        client => sub {
            my $port = shift;
            my $furl = Furl->new();
            my $res = $furl->get("http://127.0.0.1:${port}/");
            ok($res->is_success) or $res->content;
        },
        server => sub {
            my $port = shift;
            exec $^X, '-Ilib', 'script/my-app-server', '-p', $port;
            die "Should not reach here";
        },
    );
}

done_testing;

