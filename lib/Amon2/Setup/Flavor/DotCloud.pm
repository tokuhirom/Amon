use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::DotCloud;
use parent qw(Amon2::Setup::Flavor);

sub run {
    my $self = shift;

    $self->write_file('dotcloud.yml', <<'...');
www:
  type: perl
...

    $self->write_file('t/07_dotcloud.t', <<'...');
use strict;
use warnings;
use Test::More;
use Test::Requires 'YAML::Tiny';
eval { YAML::Tiny->read('dotcloud.yml') };
ok(!$@, 'valid yaml file') or diag $@;
done_testing;
...
}

1;
