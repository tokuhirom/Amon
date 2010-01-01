use strict;
use warnings;
use FindBin;
use File::Spec;
use Test::More;
{
    package MyApp::V::MT;
    use base qw/Amon::V::MT/;
}

for my $cache_mode (1..6) {
    my $v = MyApp::V::MT->new(
        {
            cache_mode   => $cache_mode,
            include_path => File::Spec->catfile( $FindBin::Bin, 'tmpl' )
        }
    );
    is $v->render('index.mt'), "okay, 5\n", "mode $cache_mode";
    is $v->render('index.mt'), "okay, 5\n";
}

done_testing;
