use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use local::lib File::Spec->catdir($FindBin::Bin, '..', 'extlib');
use Hello;
use DBIx::Skinny::Schema::Loader qw/make_schema_at/;
use FindBin;

my $c = Hello->bootstrap;
my $conf = $c->config->{'DBIx::Skinny'};

my $schema = make_schema_at( 'Hello::DB::Schema', {}, $conf );
my $dest = File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Hello', 'DB', 'Schema.pm');
open my $fh, '>', $dest or die "cannot open file '$dest': $!";
print {$fh} $schema;
close $fh;
