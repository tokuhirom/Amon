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

done_testing;
