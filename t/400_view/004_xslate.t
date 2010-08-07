use strict;
use warnings;
use Test::Requires 'Text::Xslate';
use FindBin;
use File::Spec;
use Test::More;
{
    package MyApp::V::Xslate;
    use Amon2::V::Xslate -base;
}

{
    package MyApp;
    use Amon2 -base;
}

my $c = MyApp->new();
my $v = MyApp::V::Xslate->new(
    $c,
    {
        path  => [ File::Spec->catfile( $FindBin::Bin, 'tmpl' ) ],
        cache => 0,
    }
);
is $v->render('hoge.tx', {x => 5}), "okay, 5\n";

done_testing;
