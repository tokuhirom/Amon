#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw/mkpath/;
use Getopt::Long;
use Pod::Usage;
use Text::MicroTemplate ':all';

our $module;
our $dispatcher = 'RouterSimple';
GetOptions(
    'dispatcher=s' => \$dispatcher,
    'help'         => \my $help,
) or pod2usage(0);
pod2usage(1) if $help;

my $confsrc = <<'END_OF_SRC';
-- lib/$path.pm
package <%= $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

# __PACKAGE__->load_plugin(qw/DBI/);

1;
-- lib/$path/Web.pm
package <%= $module %>::Web;
use strict;
use warnings;
use parent qw/<%= $module %> Amon2::Web/;
use File::Spec;

# load all controller classes
use Module::Find ();
Module::Find::useall("<%= $module %>::Web::C");

# custom classes
use <%= $module %>::Web::Request;
use <%= $module %>::Web::Response;
sub create_request  { <%= $module %>::Web::Request->new($_[1]) }
sub create_response { shift; <%= $module %>::Web::Response->new(@_) }

# dispatcher
use <%= $module %>::Web::Dispatcher;
sub dispatch {
    return <%= $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || die "missing configuration for Text::Xslate";
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
        %$view_conf
    });
    sub create_view { $view }
}

# load plugins
use HTTP::Session::Store::File;
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::NoCache', # do not cache the dynamic content by default
    'Web::CSRFDefender',
    'Web::HTTPSession' => {
        state => 'Cookie',
        store => HTTP::Session::Store::File->new(
            dir => File::Spec->tmpdir(),
        )
    },
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

1;
-- lib/$path/Web/Dispatcher.pm
package <%= $module %>::Web::Dispatcher;
use strict;
use warnings;
<% if ($dispatcher eq 'RouterSimple') { %>
use Amon2::Web::Dispatcher::RouterSimple;

connect '/' => 'Root#index';
<% } else { %>
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};
<% } %>

1;
-- lib/$path/Web/Request.pm
package <%= $module %>::Web::Request;
use strict;
use parent qw/Amon2::Web::Request/;
1;
-- lib/$path/Web/Response.pm
package <%= $module %>::Web::Response;
use strict;
use parent qw/Amon2::Web::Response/;
1;
-- lib/$path/Web/C/Root.pm RouterSimple
package <%= $module %>::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index.tt");
}

1;
-- config/development.pl
+{
    'DBI' => [
        'dbi:SQLite:dbname=development.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
    'Text::Xslate' => +{
    },
};
-- config/test.pl
+{
    'DBI' => [
        'dbi:SQLite:dbname=test.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
    'Text::Xslate' => +{
    },
};
-- lib/$path/ConfigLoader.pm
package <%= $module %>::ConfigLoader;
use strict;
use warnings;
use parent 'Amon2::ConfigLoader';
1;
-- sql/my.sql

-- sql/sqlite3.sql

-- tmpl/index.tt
[% WRAPPER 'include/layout.tt' %]

hello, Amon2 world!

[% END %]
-- tmpl/include/layout.tt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>[% title || '<%= $dist %>' %]</title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <link href="[% uri_for('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <header>
        <a href="[% uri_for('/') %]"><%= $dist %></a>
    </header>
    <div id="main">
        [% content %]
    </div>
    <footer>
        Powered by <a href="http://amon.64p.org/">Amon2</a>
    </footer>
</body>
</html>
-- htdocs/static/css/main.css
/* meyer-reset.css */
html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed, 
figure, figcaption, footer, header, hgroup, 
menu, nav, output, ruby, section, summary,
time, mark, audio, video {
    margin: 0;
    padding: 0;
    border: 0;
    font-size: 100%;
    font: inherit;
    vertical-align: baseline;
}
/* HTML5 display-role reset for older browsers */
article, aside, details, figcaption, figure, 
footer, header, hgroup, menu, nav, section {
    display: block;
}
body {
    line-height: 1;
}
ol, ul {
    list-style: none;
}
blockquote, q {
    quotes: none;
}
blockquote:before, blockquote:after,
q:before, q:after {
    content: '';
    content: none;
}
table {
    border-collapse: collapse;
    border-spacing: 0;
}

/* --------------------------------------------------------------

   typography.css
   * Sets up some sensible default typography.
    (from blueprint css)

-------------------------------------------------------------- */

/* Default font settings.
   The font-size percentage is of 16px. (0.75 * 16px = 12px) */
html { font-size:100.01%; }
body {
  font-size: 75%;
  color: #222;
  background: #fff;
  font-family: "Helvetica Neue", Arial, Helvetica, sans-serif;
}


/* Headings
-------------------------------------------------------------- */

h1,h2,h3,h4,h5,h6 { font-weight: normal; color: #111; }

h1 { font-size: 3em; line-height: 1; margin-bottom: 0.5em; }
h2 { font-size: 2em; margin-bottom: 0.75em; }
h3 { font-size: 1.5em; line-height: 1; margin-bottom: 1em; }
h4 { font-size: 1.2em; line-height: 1.25; margin-bottom: 1.25em; }
h5 { font-size: 1em; font-weight: bold; margin-bottom: 1.5em; }
h6 { font-size: 1em; font-weight: bold; }

h1 img, h2 img, h3 img,
h4 img, h5 img, h6 img {
  margin: 0;
}


/* Text elements
-------------------------------------------------------------- */

p           { margin: 0 0 1.5em; }
/* 
	These can be used to pull an image at the start of a paragraph, so 
	that the text flows around it (usage: <p><img class="left">Text</p>) 
 */
.left  			{ float: left !important; }
p .left			{ margin: 1.5em 1.5em 1.5em 0; padding: 0; }
.right 			{ float: right !important; }
p .right 		{ margin: 1.5em 0 1.5em 1.5em; padding: 0; }

a:focus,
a:hover     { color: #09f; }
a           { color: #06c; text-decoration: underline; }

blockquote  { margin: 1.5em; color: #666; font-style: italic; }
strong,dfn	{ font-weight: bold; }
em,dfn      { font-style: italic; }
sup, sub    { line-height: 0; }

abbr,
acronym     { border-bottom: 1px dotted #666; }
address     { margin: 0 0 1.5em; font-style: italic; }
del         { color:#666; }

pre         { margin: 1.5em 0; white-space: pre; }
pre,code,tt { font: 1em 'andale mono', 'lucida console', monospace; line-height: 1.5; }


/* Lists
-------------------------------------------------------------- */

li ul,
li ol       { margin: 0; }
ul, ol      { margin: 0 1.5em 1.5em 0; padding-left: 1.5em; }

ul          { list-style-type: disc; }
ol          { list-style-type: decimal; }

dl          { margin: 0 0 1.5em 0; }
dl dt       { font-weight: bold; }
dd          { margin-left: 1.5em;}


/* Tables
-------------------------------------------------------------- */

/* 
	Because of the need for padding on TH and TD, the vertical rhythm 
	on table cells has to be 27px, instead of the standard 18px or 36px 
	of other elements. 
 */ 
table       { margin-bottom: 1.4em; width:100%; }
th          { font-weight: bold; }
thead th    { background: #c3d9ff; }
th,td,caption { padding: 4px 10px 4px 5px; }
/*
	You can zebra-stripe your tables in outdated browsers by adding 
	the class "even" to every other table row. 
 */
tbody tr:nth-child(even) td, 
tbody tr.even td  { 
	background: #e5ecf9; 
}
tfoot       { font-style: italic; }
caption     { background: #eee; }


/* Misc classes
-------------------------------------------------------------- */

.small      { font-size: .8em; margin-bottom: 1.875em; line-height: 1.875em; }
.large      { font-size: 1.2em; line-height: 2.5em; margin-bottom: 1.25em; }
.hide       { display: none; }

.quiet      { color: #666; }
.loud       { color: #000; }
.highlight  { background:#ff0; }
.added      { background:#060; color: #fff; }
.removed    { background:#900; color: #fff; }

.first      { margin-left:0; padding-left:0; }
.last       { margin-right:0; padding-right:0; }
.top        { margin-top:0; padding-top:0; }
.bottom     { margin-bottom:0; padding-bottom:0; }

/* main */
html,body {height:100%;}

body {
    font-family: "メイリオ","Hiragino Kaku Gothic Pro","ヒラギノ角ゴ Pro W3","ＭＳ Ｐゴシック","Osaka",sans-selif;
    background-color: white;
    max-width: 960px;
    margin: 0 auto;
}

body > header {
    height: 50px;
    font-size: 36px;
    padding: 2px;
    text-align: center; }
    body > header a {
        color: black;
        font-weight: bold;
        text-decoration: none; }

#main {
    padding: 10px;
}

body > footer {
    text-align: right;
    padding-right: 10px;
    padding-top: 2px; }
    body > footer a {
        text-decoration: none;
        color: black;
        font-weight: bold;
    }

/* smart phones */
@media screen and (max-device-width: 480px) {
}

-- $dist.psgi
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use <%= $module %>::Web;
use Plack::Builder;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/|/robot\.txt$|/favicon.ico$)},
        root => File::Spec->catdir(dirname(__FILE__), 'htdocs');
    enable 'Plack::Middleware::ReverseProxy';
    <%= $module %>::Web->to_app();
};
-- Makefile.PL
use inc::Module::Install;
all_from "lib/<%= $path %>.pm";

license 'unknown';
author  'unknown';

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';
requires 'Plack::Middleware::ReverseProxy';
requires 'HTML::FillInForm::Lite';
requires 'Time::Piece';
recursive_author_tests('xt');

WriteAll;
-- t/00_compile.t
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <%= $module %>
    <%= $module %>::Web
    <%= $module %>::Web::Dispatcher
);

done_testing;
-- t/Util.pm
package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;                       
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

1;
-- t/01_root.t
use strict;
use warnings;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi '<%= $dist %>.psgi';
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
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = Plack::Util::load_psgi '<%= $dist %>.psgi';

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
<%= $module %>
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
eval q{
	use Perl::Critic 1.113;
	use Test::Perl::Critic 1.02 -exclude => [
		'Subroutines::ProhibitSubroutinePrototypes',
		'Subroutines::ProhibitExplicitReturnUndef',
		'TestingAndDebugging::ProhibitNoStrict',
		'ControlStructures::ProhibitMutatingListFunctions',
	];
};
plan skip_all => "Test::Perl::Critic 1.02+ and Perl::Critic 1.113+ is not installed." if $@;
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
equivalent_modules = Mouse Mouse::Role Moose Amon2 Amon2::Web Amon2::Web::C Amon2::V::MT::Context Amon2::Web::Dispatcher Amon2::V::MT Amon2::Config Amon2::Web::Dispatcher::HTTPxDispatcher Any::Moose Amon2::Web::Dispatcher::RouterSimple Amon2::Web::Dispatcher::Lite common::sense
[-Subroutines::ProhibitExplicitReturnUndef]
-- .gitignore
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
development.db
est.db
END_OF_SRC

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

    mkdir $dist or die "Cannot mkdir '$dist': $!";
    chdir $dist or die $!;
    _mkpath "lib/$path";
    _mkpath "lib/$path/Web/";
    _mkpath "lib/$path/Web/C" unless $dispatcher eq 'Lite';
    _mkpath "lib/$path/M";
    _mkpath "lib/$path/DB/";
    _mkpath "tmpl";
    _mkpath "tmpl/include/";
    _mkpath "t";
    _mkpath "xt";
    _mkpath "sql/";
    _mkpath "config/";
    _mkpath "script/";
    _mkpath "script/cron/";
    _mkpath "script/tmp/";
    _mkpath "script/maintenance/";
    _mkpath "htdocs/static/css/";
    _mkpath "htdocs/static/img/";
    _mkpath "htdocs/static/js/";
    _mkpath "extlib/";

    my $conf = _parse_conf($confsrc);
    while (my ($file, $tmpl) = each %$conf) {
        $file =~ s/(\$\w+)/$1/gee;
        my $code = Text::MicroTemplate->new(
            tag_start => '<%',
            tag_end   => '%>',
            line_start => '%%%',
            template => $tmpl,
        )->code;
        my $sub = eval "package main;our \$module; sub { Text::MicroTemplate::encoded_string(($code)->(\@_))}";
        die $@ if $@;

        my $res = $sub->()->as_string;

        print "writing $file\n";
        open my $fh, '>', $file or die "Can't open file($file):$!";
        print $fh $res;
        close $fh;
    }
}

sub _parse_conf {
    my $fname;
    my $res;
    my $tag;
    LOOP: for my $line (split /\n/, $confsrc) {
        if ($line =~ /^--\s+(\S+)(?:\s*(\S+))?$/) {
            $fname = $1;
            $tag   = $2;
        } else {
            $fname or die "missing filename for first content";
            next LOOP if $tag && $tag eq 'RouterSimple' && $dispatcher ne 'RouterSimple';
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

