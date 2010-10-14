my $tmpdir = '/tmp/hello.session/';
mkdir $tmpdir;
use Hello::V::MT::Context;

{
    'DB' => {
        dsn => 'dbi:SQLite:hello.db',
    },
    'HTTP::Session::Store::File' => {
        dir => $tmpdir,
    },
    'Text::MicroTemplate::File' => {
        include_path => 'tmpl',
        package_name => 'Hello::V::MT::Context',
    },
}
