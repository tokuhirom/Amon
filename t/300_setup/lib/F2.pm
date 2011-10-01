use strict;
use warnings;
use utf8;

package F2;

sub parent { '+F1' }

1;
__DATA__

@@ X
: cascade "!"
: after f -> {
ZZZ
: }
