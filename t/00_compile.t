use strict;
use warnings;
use Test::More;

use_ok($_) for qw/
    Amon2
    Amon2::Web
    Amon2::Web::Response
    Amon2::Web::Request
/;

use Plack;

diag "Plack: $Plack::VERSION\n";
diag "Perl: $] $^X\n";
diag "INC: " . join(" ", @INC) . "\n";

done_testing;
