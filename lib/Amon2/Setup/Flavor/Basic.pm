use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Basic;
use parent qw/Amon2::Setup::Flavor::Minimum/;
use Amon2::Setup::Asset::jQuery;

sub run {
    my $self = shift;

    $self->SUPER::run();

    $self->mkpath('htdocs/static/img/');
    $self->mkpath('htdocs/static/js/');

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

# __PACKAGE__->load_plugin(qw/DBI/);

1;
...

    $self->write_file('lib/<<PATH>>/Web.pm', <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

# load all controller classes
use Module::Find ();
Module::Find::useall("<% $module %>::Web::C");

# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return <% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
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
...

    $self->write_file("lib/<<PATH>>/Web/Dispatcher.pm", <<'...');
package <% $module %>::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};

1;
...

    $self->write_file("config/development.pl", <<'...');
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
...

    $self->write_file("config/test.pl", <<'...');
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
...

    $self->write_file("lib/<<PATH>>/ConfigLoader.pm", <<'...');
package <% $module %>::ConfigLoader;
use strict;
use warnings;
use parent 'Amon2::ConfigLoader';
1;
...

    $self->write_file("sql/my.sql", '');
    $self->write_file("sql/sqlite3.sql", '');

    $self->write_file('tmpl/index.tt', <<'...');
[% WRAPPER 'include/layout.tt' %]

hello, Amon2 world!

[% END %]
...

    $self->write_file('tmpl/include/layout.tt', <<'...');
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
...

    $self->write_file('htdocs/static/js/' . Amon2::Setup::Asset::jQuery->jquery_min_basename(), Amon2::Setup::Asset::jQuery->jquery_min_content());

    $self->write_file('htdocs/static/css/main.css', <<'...');
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
...

    $self->write_file("t/00_compile.t", <<'...');
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
    <% $module %>::Web::Dispatcher
);

done_testing;
...

    $self->write_file("xt/02_perlcritic.t", <<'...');
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
...

    $self->write_file('.gitignore', <<'...');
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
nytprof/
development.db
test.db
...
}

1;
