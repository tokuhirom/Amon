package t::Utils;
use strict;
use warnings;
use Hello::Web;
use File::Slurp;
use File::Temp qw/tempdir/;

my $sessiondir = tempdir(CLEANUP => 1);

sub mk_db {
    my ($class, $c) = @_;
    my $sql = read_file('sql/sqlite.sql');
    for my $s (split /;/, $sql) {
        next unless $s =~ /\S/;
        $c->get('DB')->dbh->do($s);
    }
}

sub mk_app {
    my ($class) = @_;
    my $c = Hello::Web->new(
        config => {
            'DB' => {
                dsn => 'dbi:SQLite:'
            },
            'HTTP::Session::Store::File' => {
                dir => $sessiondir,
            },
        }
    );
    $class->mk_db($c);
    return sub { $c->run(shift) };
}

1;
