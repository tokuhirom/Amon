package Amon::Web::C;
use strict;
use warnings;
use Amon::Web::Declare;

sub import {
    strict->import;
    warnings->import;
    Amon::Web::Declare->export_to_level(1);
}

1;
__END__

=head1 NAME

Amon::Web::C - Amon controller class

=head1 SYNOPSIS

    package MyApp::Web::C;
    use Amon::Web::C;

=head1 DESCRIPTION

This class exports some useful function for controller class.

In Amon ideology, a controller class is just a POPO(plain old perl object).
Then, you can write controller class without this class, if you want.

=head1 SEE ALSO

L<Amon>

=cut

