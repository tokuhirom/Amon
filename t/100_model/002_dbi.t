use strict;
use warnings;
use Test::More;
use Amon::M::DBI;
use Test::Requires 'DBI', 'DBD::SQLite';

my $m = Amon::M::DBI->new({
    connect_info => [
        'dbi:SQLite:', '', '', {RaiseError => 1, AutoCommit => 1}
    ]
});
isa_ok $m->dbh, 'DBI::db';
ok $m->dbh->{sqlite_version}, "sqlite version is @{[ $m->dbh->{sqlite_version} ]}";

done_testing;
