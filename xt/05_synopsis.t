use strict;
use warnings;
use utf8;

use Test::More;

eval "use Test::Synopsis; use ExtUtils::Manifest";
plan skip_all => "Test::Synopsis, ExtUtils::Manifest required for testing" if $@;
plan skip_all => "There is no MANIFEST file" unless -f 'MANIFEST';

my $manifest = ExtUtils::Manifest::maniread();
my @files =
  grep !m{^lib/Amon2/Setup/Flavor/.+\.pm$},
  grep !m{^lib/Amon2/Lite\.pm$},
  grep !m{^lib/Amon2/Web\.pm$},
  grep m!^lib/.*\.p(od|m)$!,
  keys %$manifest;

plan(tests => 1 * @files);
my $n = 0;
for my $module (@files) {
    my($code, $line, @option) = Test::Synopsis::extract_synopsis($module);
    unless ($code) {
        ok(1, "No SYNOPSIS code: $module");
        next;
    }

    my $option = join(";", @option);
    my $test   = qq(package Test::Synopsis::Sandbox::$n\n#line $line "$module"\n$option; sub { $code });
    my $ok = do {
        package
            Test::Synopsis::Sandbox;
        eval $test; ## no critic
    };
    ok($ok, $module);
    diag($@) unless $ok;

    $n++;
}

