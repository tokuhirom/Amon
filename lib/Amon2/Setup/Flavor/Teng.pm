use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Teng;

sub plugins { 'DBI' }

1;
__DATA__

@@ Makefile.PL
: cascade "!"
: after prereq_pm -> {
        'Teng'                     => '0.12',
: }

@@ <<WEB_CONTEXT_PATH>>
: cascade "!";
: after load_plugins -> {
__PACKAGE__->load_plugin(qw/DBI/);

use Teng;
use <: $module :>::DB::Schema;
sub db {
    my $self = shift;
    if (!defined $self->{db}) {
        my $dbh = $self->dbh;
        $self->{db} = Teng->new(
            dbh => $dbh,
            schema => '<: $module :>::DB::Schema',
        );
    }
    return $self->{db};
}
: }

@@ lib/<<PATH>>/DB.pm
package <: $module :>::DB;
use parent 'Teng';
1;

@@ t/00_compile.t
: cascade "!";
: after modules -> {
    <: $module :>::DB
    <: $module :>::DB::Schema
: }

@@ lib/<<PATH>>/DB/.gitignore

@@ script/make_schema.pl
use strict;
use warnings;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'extlib', 'lib', 'perl5' );
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib' );
use <: $module :>;
use Teng::Schema::Dumper;

my $c      = <: $module :>->bootstrap;
my $schema = Teng::Schema::Dumper->dump(
    dbh       => $c->dbh,
    namespace => '<: $module :>::DB',
);

my $dest = File::Spec->catfile( dirname(__FILE__), '..', 'lib', '<: $module :>',
    'DB', 'Schema.pm' );
open my $fh, '>', $dest or die "Cannot open file: $dest: $!";
print {$fh} $schema;
close $fh;

