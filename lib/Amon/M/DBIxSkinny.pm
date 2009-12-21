package Amon::M::DBIxSkinny;
use strict;
use warnings;

# yes, nop.
require DBIx::Skinny;
sub import { goto \&DBIx::Skinny::import; }

1;
__END__

=head1 NAME

Amon::M::DBIxSkinny - DBIx::Skinny wrapper for Amon

=head1 SYNOPSIS

  package Neko::M::DB;
  use Amon::M::DBIxSkinny;

  package Neko::M::DB::Schema;
  use DBIx::Skinny::Schema;
  install_table user => schema {
    pk 'id';
    columns qw/id name/;
  };

  # in your controller
  model("DB")->get('user' => 1);

=head1 DESCRIPTION

This is L<DBIx::Skinny> bindings for Amon.

=head1 AUTHOR

Tokuhiro Matsuno

=cut

