use strict;
use warnings;
use Test::More;
use Test::Requires 'HTML::FillInForm';
use File::Spec;
use File::Temp qw/tempdir/;

my $tmp = tempdir(CLEANUP => 1);

{
    package MyApp;
    use parent qw/Amon2/;

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Tiffany;
    sub create_view { Tiffany->load('Text::MicroTemplate::File', {include_path => [$tmp]}) }
    sub dispatch { MyApp::Web::Dispatcher->dispatch(shift) }
    __PACKAGE__->load_plugins(
        'Web::FillInForm' => {},
    );
}

my $c = MyApp::Web->bootstrap();

{
    open my $fh, '>', File::Spec->catfile($tmp, 'hoge.mt') or die $!;
    print $fh <<'...';
<html>
<head>
</head>
<body>
<form action="/" method="post">
<input type="text" name="body" />
<input type="submit" name="post" />
</form>
</body>
</html>
...
    close $fh;
}

my $res = $c->render('hoge.mt')->fillin_form({body => "hello"});
like $res->body(), qr{<input value="hello" name="body" type="text" />};
done_testing;
