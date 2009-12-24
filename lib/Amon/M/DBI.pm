package Amon::M::DBI;
use strict;
use warnings;
use DBI;

sub new {
    my ($class, $conf) = @_;
    my $connect_info = $conf->{connect_info} or die "missing configuration 'connect_info' for $class";
    bless { connect_info => $connect_info }, $class;
}

sub dbh {
    my $self = shift;
    $self->{dbh} ||= do {
        DBI->connect( @{ $self->{connect_info} } ) or die $DBI::errstr;
    };
}

1;
__END__

=head1 NAME

Amon::M::DBI - Amon DBI Model Class

=head1 SYNOPSIS

    package Your::M::DBI;
    use base qw/Amon::M::DBI/;
    1;

    # in your configuration
    Your::Web->app({
        'M::DBI' => {
            connect_info => [
                'dbi:SQLite:', '', ''
            ],
        }
    });

=head1 SEE ALSO

L<DBI>, L<Amon>

=cut

