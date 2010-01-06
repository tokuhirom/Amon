package Amon::Factory::DBI;
use strict;
use warnings;
use DBI;

sub create {
    my ($class, $c, $klass, $conf) = @_;
    if ($conf->{dbh}) {
        return $conf->{dbh}; # return dbh itself, this is useful for testing.
    } else {
        my $connect_info = $conf->{connect_info} or die "missing configuration 'connect_info' for DBI";
        return DBI->connect( @{ $connect_info } ) or die $DBI::errstr;
    }
}

1;
