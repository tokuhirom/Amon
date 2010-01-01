package t::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use Test::More;
use App::Prove;

our @EXPORT = qw/run_app_test/;

sub run_app_test {
    my $name = shift;
    chdir "t/apps/$name/" or die $!;

    my $app = App::Prove->new();
    warn File::Spec->catfile($FindBin::Bin, '..', 'lib');
    $app->process_args('-Ilib', '-I'.File::Spec->catfile($FindBin::Bin, '..', '..', 'lib'), <t/*.t>);
    ok($app->run);
    done_testing;
}

1;
