package t::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use Test::More;
use App::Prove;
use File::Basename;

our @EXPORT = qw/run_app_test/;

sub run_app_test {
    my $name = shift;
    chdir "t/apps/$name/" or die $!;

    my $app = App::Prove->new();
    $app->process_args('-Ilib', '-I'.File::Spec->catfile(dirname(__FILE__), '..', 'lib'), <t/*.t>);
    ok($app->run);
    done_testing;
}

1;
