use strict;
use warnings;
use utf8;
use Test::More;
use Amon::V::MT;

{
    package MyApp::V::MT;
    use Amon::V::MT -base;
}

{
    package MyApp;
    use Amon -base;
}

my $c = MyApp->new();
my $v = MyApp::V::MT->new(
    $c,
    {
        include_path => File::Spec->catfile( $FindBin::Bin, 'tmpl' ),
        open_layer   => ':encoding(cp932)',
    }
);
is $v->render('cp932.mt'), "はい, 5\n", "cp932";

done_testing;
