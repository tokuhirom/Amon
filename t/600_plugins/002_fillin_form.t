use strict;
use warnings;
use Test::More;
use Test::Requires 'HTML::FillInForm', 'Text::MicroTemplate::File';
use File::Spec;
use File::Temp qw/tempdir/;
use Plack::Response;

my $tmp = tempdir(CLEANUP => 1);

{
    package MyApp;
    use parent qw/Amon2/;

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Tiffany;
    sub create_view { Tiffany->load('Text::MicroTemplate::File', {include_path => [$tmp]}) }
    sub dispatch {
        my $c = shift;
        $c->fillin_form(+{body => 'hello'});
        $c->render('hoge.mt');
    }
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

subtest 'new style' => sub {
    my $res = MyApp::Web->to_app()->(+{});
    like $res->[2]->[0], qr{<input value="hello" name="body" type="text" />};
    is Plack::Util::header_get($res->[1], 'Content-Length'), length($res->[2]->[0]);
};

subtest 'old style' => sub {
    local $SIG{__WARN__} = sub { };
    my $res = $c->render('hoge.mt')->fillin_form({body => "hello"});
    like $res->body(), qr{<input value="hello" name="body" type="text" />};
    is $res->content_length, length($res->body);
};

done_testing;

