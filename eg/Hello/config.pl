my $tmpdir = '/tmp/hello.session/';
mkdir $tmpdir;

{
    'DB' => {
        dsn => 'dbi:SQLite:hello.db',
    },
    'HTTP::Session::Store::File' => {
        dir => $tmpdir,
    },
}
