package Hello::DB::Schema;
use DBIx::Skinny::Schema;

install_table status => schema {
    pk 'status_id';
    columns qw/status_id user_id body/;
};

install_table user => schema {
    pk 'user_id';
    columns qw/user_id email nick password/;
};

1;