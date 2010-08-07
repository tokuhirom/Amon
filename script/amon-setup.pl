#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw/mkpath/;
use Getopt::Long;
use Pod::Usage;
use Text::MicroTemplate ':all';

my $perlver = $] >= 5.010000 ? '5.10' : '5.8';
our $module;
GetOptions(
'perlver=s' => \$perlver,
'help' => \my $help,
) or pod2usage(0);
pod2usage(1) if $help;

my $confsrc = <<'...';
-- lib/$path.pm
package [%= $module %];
use Amon2 -base;
__PACKAGE__->load_plugins(qw/ConfigLoader/);
1;
-- lib/$path/Web.pm
package [%= $module %]::Web;
use Amon2::Web -base => (
    default_view_class => 'Text::Xslate',
    base_class         => '[%= $module %]',
);
1;
-- lib/$path/V/MT/Context.pm
package [%= $module %]::V::MT::Context;
use Amon2::V::MT::Context;
1;
-- lib/$path/Web/Dispatcher.pm
% my $perlver = shift;
package [%= $module %]::Web::Dispatcher;
use Amon2::Web::Dispatcher::RouterSimple;

connect '/' => {controller => 'Root', action => 'index'};

1;
-- lib/$path/Web/C/Root.pm
package [%= $module %]::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index.mt");
}

1;
-- config/development.pl
+{
    'Tfall::Text::Xslate' => {
        path => ['tmpl/'],
    },
};
-- lib/$path/ConfigLoader.pm
package [%= $module %]::ConfigLoader;
use strict;
use parent 'Amon2::ConfigLoader';
1;
-- tmpl/index.mt
? extends 'base.mt';
? block title => '[%= $dist %] page';
? block content => sub { 'hello, Amon2 world!' };
-- tmpl/base.mt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title><? block title => '[%= $dist %]' ?></title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <link href="<?= uri_for('/static/css/main.css') ?>" rel="stylesheet" type="text/css" media="screen" />
</head>
<body>
    <div id="Container">
        <div id="Header">
            <a href="<?= uri_for('/') ?>">Amon2 Startup Page</a>
        </div>
        <div id="Content">
            <? block content => 'body here' ?>
        </div>
        <div id="FooterContainer"><div id="Footer">
            Powered by Amon2
        </div></div>
    </div>
</body>
</html>
-- htdocs/static/css/main.css
/* reset.css */
html, body, div, span, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, code, del, dfn, em, img, q, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td {margin:0;padding:0;border:0;font-weight:inherit;font-style:inherit;font-size:100%;font-family:inherit;vertical-align:baseline;}
body {line-height:1.5;}
table {border-collapse:separate;border-spacing:0;}
caption, th, td {text-align:left;font-weight:normal;}
table, td, th {vertical-align:middle;}
blockquote:before, blockquote:after, q:before, q:after {content:"";}
blockquote, q {quotes:"" "";}
a img {border:none;}

/* main */
html,body {height:100%;}
body > #Container {height:auto;}

body {
    background-image: url(http://lab.rails2u.com/bgmaker/slash.png?margin=3&linecolor=FF0084&bgcolor=000000);
    color: white;
    font-family: "メイリオ","Hiragino Kaku Gothic Pro","ヒラギノ角ゴ Pro W3","ＭＳ Ｐゴシック","Osaka",sans-selif;
}

#Container {
    width: 780px;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 0px;
    border-left: black solid 1px;
    border-right: black solid 1px;
    margin-top: 0px;
    height: 100%;
    min-height:100%;
    background-color: white;
    color: black;
}

#Header {
    background-image: url(http://lab.rails2u.com/bgmaker/gradation.png?margin=3&linecolor=FF0084&bgcolor=000000);
    height: 50px;
    font-size: 36px;
    padding: 2px;
    text-align: center;
}

#Header a {
    color: black;
    font-weight: bold;
    text-decoration: none;
}

#Content {
    padding: 10px;
}
form.nopaste {
    text-align: center;
}
form.nopaste textarea {
    width: 80%;
    margin: auto;
}
form.nopaste p.submit-btn input {
    margin: 10px;
    font-size: 900%;
    height: 40px;
    width: 100px;
}

#FooterContainer {
    border-top: 1px solid black;
    font-size: 10px;
    color: black;
    position:absolute;
    bottom:0px;
    height:20px;
    width:780px;
}
#Footer {
    text-align: right;
    padding-right: 10px;
    padding-top: 2px;
}

-- $dist.psgi
use [%= $module %]::Web;
use Plack::Builder;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => './htdocs/';
    [%= $module %]::Web->to_app();
};
-- Makefile.PL
use inc::Module::Install;
all_from "lib/[%= $path %].pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';
recursive_author_tests('xt');

WriteAll;
-- t/01_root.t
use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi '[%= $dist %].psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
-- t/02_mech.t
use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = Plack::Util::load_psgi '[%= $dist %].psgi';

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');

done_testing;
-- xt/01_podspell.t
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
[%= $module %]
Tokuhiro Matsuno
Test::TCP
tokuhirom
AAJKLFJEF
GMAIL
COM
Tatsuhiko
Miyagawa
Kazuhiro
Osawa
lestrrat
typester
cho45
charsbar
coji
clouder
gunyarakun
hio_d
hirose31
ikebe
kan
kazeburo
daisuke
maki
TODO
kazuhooku
FAQ
Amon2
DBI
PSGI
URL
XS
env
.pm
-- xt/02_perlcritic.t
use strict;
use Test::More;
eval q{ use Test::Perl::Critic -profile => 'xt/perlcriticrc' };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok('lib');
-- xt/03_pod.t
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
-- xt/perlcriticrc
[TestingAndDebugging::ProhibitNoStrict]
allow=refs
[-Subroutines::ProhibitSubroutinePrototypes]
[TestingAndDebugging::RequireUseStrict]
equivalent_modules = Mouse Mouse::Role Moose Amon2 Amon2::Web Amon2::Web::C Amon2::V::MT::Context Amon2::Web::Dispatcher Amon2::V::MT Amon2::Config DBIx::Skinny DBIx::Skinny::Schema Amon2::Web::Dispatcher::HTTPxDispatcher Any::Moose Amon2::Web::Dispatcher::RouterSimple DBIx::Skinny DBIx::Skinny::Schema Amon2::Web::Dispatcher::Lite common::sense
[-Subroutines::ProhibitExplicitReturnUndef]
-- .gitignore
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
...

&main;exit;

sub _mkpath {
    my $d = shift;
    print "mkdir $d\n";
    mkpath $d;
}

sub main {
    $module = shift @ARGV or pod2usage(0);
    $module =~ s!-!::!g;

    # $module = "Foo::Bar"
    # $dist   = "Foo-Bar"
    # $path   = "Foo/Bar"
    my @pkg  = split /::/, $module;
    my $dist = join "-", @pkg;
    my $path = join "/", @pkg;

    mkdir $dist or die $!;
    chdir $dist or die $!;
    _mkpath "lib/$path";
    _mkpath "lib/$path/V";
    _mkpath "lib/$path/V/MT";
    _mkpath "lib/$path/Web/C";
    _mkpath "lib/$path/M";
    _mkpath "lib/$path/DB/";
    _mkpath "tmpl";
    _mkpath "t";
    _mkpath "xt";
    _mkpath "config/";
    _mkpath "htdocs/static/css/";
    _mkpath "htdocs/static/img/";
    _mkpath "htdocs/static/js/";

    my $conf = _parse_conf($confsrc);
    while (my ($file, $tmpl) = each %$conf) {
        $file =~ s/(\$\w+)/$1/gee;
        my $code = Text::MicroTemplate->new(
            tag_start => '[%',
            tag_end   => '%]',
            line_start => '%',
            template => $tmpl,
        )->code;
        my $sub = eval "package main;our \$module; sub { Text::MicroTemplate::encoded_string(($code)->(\@_))}";
        die $@ if $@;

        my $res = $sub->($perlver)->as_string;

        print "writing $file\n";
        open my $fh, '>', $file or die "Can't open file($file):$!";
        print $fh $res;
        close $fh;
    }
}

sub _parse_conf {
    my $fname;
    my $res;
    for my $line (split /\n/, $confsrc) {
        if ($line =~ /^--\s+(.+)$/) {
            $fname = $1;
        } else {
            $fname or die "missing filename for first content";
            $res->{$fname} .= "$line\n";
        }
    }
    return $res;
}

__END__

=head1 SYNOPSIS

    % amon-setup.pl MyApp

=head1 AUTHOR

Tokuhiro Matsuno

=cut

