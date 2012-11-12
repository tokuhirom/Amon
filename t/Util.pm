package t::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;
use FindBin;
use File::Basename;
use File::Spec;
use lib File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', 'lib'));
use Test::More;
use App::Prove;
use File::Basename;

our @EXPORT = qw/run_app_test slurp/;

sub run_app_test {
    my $name = shift;

    my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', 'lib'));

    chdir "eg/apps/$name/" or die $!;

    my $app = App::Prove->new();
    $app->process_args('--norc', '-Ilib', "-I$libpath", <t/*.t>);
    ok($app->run, 'all tests ok');
    done_testing;
}

sub slurp {
	my $fname = shift;
	open my $fh, '<', $fname or die "$fname: $!";
	do { local $/; <$fh> };
}

1;
