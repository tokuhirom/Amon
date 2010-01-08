use strict;
use warnings;
use Test::More;
use Test::Requires 'DBI', 'DBD::SQLite';
use Amon::Factory::DBI;

{
    package MyApp;
    use Amon -base;
}

my $c = MyApp->new;
my $m = Amon::Factory::DBI->create(
    $c, 'DBI' => {
        connect_info => [
            'dbi:SQLite:', '', '', {RaiseError => 1, AutoCommit => 1}
        ],
    },
);
isa_ok $m, 'DBI::db';
ok $m->{sqlite_version}, "sqlite version is @{[ $m->{sqlite_version} ]}";

done_testing;
