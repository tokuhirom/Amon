use strict;
use warnings;
use utf8;
use Plack::Util;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
$Plack::Test::Impl = "Server";

use Amon2;

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch {
        my $c = shift;
        $c->streaming(sub {
            my ($respond) = @_;
            my $writer = $respond->(
                [200, ['Content-Type', 'text/html']]);
            $writer->write("<html>\n");
            for my $i (1..5) {
                $writer->write("<div>$i</div>\n");
            }
            $writer->write("</html>\n");
            $writer->close;
        });
    }
}

{
    package MyApp;
    use parent qw/Amon2/;
    __PACKAGE__->load_plugin('Amon2::Plugin::Web::Streaming');
}

my $app = MyApp::Web->to_app();

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->content, <<"...";
<html>
<div>1</div>
<div>2</div>
<div>3</div>
<div>4</div>
<div>5</div>
</html>
...
};

done_testing;
