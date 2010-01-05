use strict;
use warnings;
use Test::More;
use Test::Requires 'HTML::FillInForm';

BEGIN {
    $INC{'MyApp/Web/Dispatcher.pm'} = __FILE__;
    $INC{'MyApp/V/MT.pm'} = __FILE__;
    $INC{'MyApp.pm'} = __FILE__;
}


{
    package MyApp;
    use Amon -base;
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
    __PACKAGE__->load_plugins(
        'FillInForm' => {},
    );
}

my $c = MyApp::Web->new();
my $res = $c->response_class->new(200, ['Content-Type' => 'text/html'], <<'...');
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
$res = $res->fillin_form({body => "hello"});
like $res->body(), qr{<input value="hello" name="body" type="text" />};
done_testing;
