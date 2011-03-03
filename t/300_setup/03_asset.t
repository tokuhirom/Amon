use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Setup::Asset::jQuery;
use Amon2::Setup::Asset::Blueprint;

like(Amon2::Setup::Asset::jQuery->jquery_min_content(), qr/Resig/);
like(Amon2::Setup::Asset::jQuery->jquery_min_basename(), qr/^jquery-.+\.js$/);

like(Amon2::Setup::Asset::Blueprint->ie_css(), qr/ie.css/);
like(Amon2::Setup::Asset::Blueprint->screen_css(), qr/typography.css/);
like(Amon2::Setup::Asset::Blueprint->print_css(), qr/print.css/);

done_testing;

