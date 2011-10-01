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
our @EXPORT_OK = qw(slurp);

sub run_app_test {
    my $name = shift;

    my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', 'lib'));

    chdir "t/apps/$name/" or die $!;

    my $app = App::Prove->new();
    $app->process_args('-Ilib', "-I$libpath", <t/*.t>);
    ok($app->run);
    done_testing;
}

sub slurp {
    my $fname = shift;
    open my $fh, '<:utf8', $fname or die "Cannot open $fname: $!";
    do { local $/; <$fh> };
}

package #
    t::Util::Chdir;
use File::Temp qw(tempdir);

sub new {
    my $class = shift;
    my $dir = shift || tempdir(CLEANUP => 1);
    my $cwd = Cwd::getcwd();
    chdir($dir);
    bless [$cwd, $dir], $class;
}

sub DESTROY {
    my $self = shift;
    chdir $self->[0];
}

1;
