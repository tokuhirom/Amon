package Hello;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='4.00';

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

use Hello::DB;

sub db {
    my ($self) = @_;
    $self->{db} //= do {
        my $conf = $self->config->{'DBIx::Skinny'} or die "missing configuration for 'DBIx::Skinny'";
        Hello::DB->new($conf);
    };
}


1;
