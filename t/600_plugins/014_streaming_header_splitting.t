use strict;
use warnings;
use utf8;
use Plack::Util;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use Test::Requires 'Test::WWW::Mechanize::PSGI';
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
                [200, ['Content-Type', "text/html\015\012hogehoge"]]);
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

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
my $res = $mech->get('/');
like $res->code, qr/\A5\d\d\z/;
unlike $res->content, qr/<html>/;

done_testing;
