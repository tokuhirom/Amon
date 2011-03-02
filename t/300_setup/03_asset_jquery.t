use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Setup::Asset::jQuery;

like(Amon2::Setup::Asset::jQuery->jquery_min_content(), qr/Resig/);
like(Amon2::Setup::Asset::jQuery->jquery_min_basename(), qr/^jquery-.+\.js$/);

done_testing;

