use strict;
use warnings;
use Test::More;
use Test::Requires 'DBI', 'DBD::SQLite', 'DBIx::Skinny';

{
    package Neko::M::DB;
    use Amon::M::DBIxSkinny;
}

{
    package Neko::M::DB::Schema;
    use DBIx::Skinny::Schema;
    install_table user => schema {
        pk 'id';
        columns qw(
                      id
                      name
              );
    };
}

my $db = Neko::M::DB->new(
    {
        dsn => 'dbi:SQLite:',
    }
);
$db->dbh->do(q{
create table user (
  id int auto_increment not null primary key,
  name varchar(255) not null
);
});
my $row1 = $db->insert('user' => { id => 1, name => 'ukonmanaho' });
is $row1->id, 1;
my $row2 = $db->insert('user' => { id => 2, name => 'yappo' });
is $row2->id, 2;
is $row2->name, 'yappo';
my ($x) = $db->search('user' => {
    id => 2,
});
is $x->name, 'yappo';
done_testing;
