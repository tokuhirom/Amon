use strict;
use warnings;
use Test::Requires 'DBI', 'DBD::SQLite', 'Data::Model';
use Test::More;
use Amon::Factory::DataModel;

BEGIN {
    $INC{'Neko/DB.pm'} = __FILE__;
}

{
    package Neko::DB;
    use base qw/Data::Model/;
    use Data::Model::Schema;

    install_model user => schema {
        # primary key
        key 'id';

        # カラム定義
        column 'id' => int => {
            auto_increment => 1,
            required => 1,
            unsigned => 1,
        };
        utf8_column 'name' => 'varchar' => {
            required => 1,
            size => 255,
        };
    };
}

{
    package Neko;
    use Amon -base;
}

my $c = Neko->new;
my $db = Amon::Factory::DataModel->create(
    $c, 'Neko::DB', {
        module => 'DBI',
        config => { dsn => 'dbi:SQLite:', }
    },
);
for my $target ($db->schema_names) {
    my $dbh = $db->get_driver($target)->rw_handle;
    for my $sql ($db->as_sqls($target)) {
        $dbh->do($sql);
    }
}
my $row1 = $db->set('user' => {name => 'yappo'});
my $row2 = $db->set('user' => {name => 'ukonmanaho'});
is $row1->id, 1;
is $row2->id, 2;
my ($got) = $db->get('user' => 2);
is $got->name, 'ukonmanaho';

done_testing;
