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

use <%= $module %>::DBI;
sub dbh {
    my ($self) = @_;

    if (!defined $self->{dbh}) {
        my $conf = $self->config->{'DBI'} or die "missing configuration for 'DBI'";
        $self->{dbh} = <%= $module %>::DBI->connect(@$conf);
    }
    return $self->{dbh};
}

1;
-- lib/$path/DBI.pm
use strict;
use warnings;

package <%= $module %>::DBI;
use parent qw/DBI/;

sub connect {
	my ($self, $dsn, $user, $pass, $attr) = @_;
    $attr->{RaiseError} = 0;
    if ($DBI::VERSION >= 1.614) {
        $attr->{AutoInactiveDestroy} = 1 unless exists $attr->{AutoInactiveDestroy};
    }
	if ($dsn =~ /^dbi:SQLite:/) {
		$attr->{sqlite_unicode} = 1 unless exists $attr->{sqlite_unicode};
	}
    if ($dsn =~ /^dbi:mysql:/) {
        $attr->{mysql_enable_utf8} = 1 unless exists $attr->{mysql_enable_utf8};
    }
	return $self->SUPER::connect($dsn, $user, $pass, $attr) or die "Cannot connect to server: $DBI::errstr";
}

package <%= $module %>::DBI::dr;
our @ISA = qw(DBI::dr);

package <%= $module %>::DBI::db;
our @ISA = qw(DBI::db);

use DBIx::TransactionManager;
use SQL::Interp ();

sub _txn_manager {
    my $self = shift;
    $self->{private_txn_manager} //= DBIx::TransactionManager->new($self);
}

sub txn_scope { $_[0]->_txn_manager->txn_scope(caller => [caller(0)]) }

sub do_i {
    my $self = shift;
    my ($sql, @bind) = SQL::Interp::sql_interp(@_);
    $self->do($sql, {}, @bind);
}

sub insert {
    my ($self, $table, $vars) = @_;
    $self->do_i("INSERT INTO $table", $vars);
}

sub prepare {
    my ($self, @args) = @_;
    my $sth = $self->SUPER::prepare(@args) or do {
        <%= $module %>::DBI::Util::handle_error($_[1], [], $self->errstr);
    };
    $sth->{private_sql} = $_[1];
    return $sth;
}

package <%= $module %>::DBI::st;
our @ISA = qw(DBI::st);

sub execute {
    my ($self, @args) = @_;
    $self->SUPER::execute(@args) or do {
        <%= $module %>::DBI::Util::handle_error($self->{private_sql}, \@args, $self->errstr);
    };
}

sub sql { $_[0]->{private_sql} }

package <%= $module %>::DBI::Util;
use Carp::Clan qw{^(DBI::|<%= $module %>::DBI::|DBD::)};
use Data::Dumper ();

sub handle_error {
    my ( $stmt, $bind, $reason ) = @_;

    $stmt =~ s/\n/\n          /gm;
    my $err = sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ <%= $module %>::DBI 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
    $err =~ s/\n\Z//;
    croak $err;
}

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
use Tiffany::Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || die "missing configuration for Text::Xslate";
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl') ];
    }
    my $view = Tiffany::Text::Xslate->new(+{
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
        'dbi:SQLite:memory:',
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
[% INCLUDE 'include/header.tt' %]

hello, Amon2 world!

[% INCLUDE 'include/footer.tt' %]
-- tmpl/include/header.tt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title><%= $dist %></title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0"]]>
    <meta name="format-detection" content="telephone=no" />
    <link href="[% uri_for('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
</head>
<body>
    <div id="Container">
        <div id="Header">
            <a href="[% uri_for('/') %]"><%= $dist %></a>
        </div>
        <div id="Content">
-- tmpl/include/footer.tt
        </div>
        <div id="FooterContainer"><div id="Footer">
            Powered by <a href="http://amon.64p.org/">Amon2</a>
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
    color: white;
    font-family: "メイリオ","Hiragino Kaku Gothic Pro","ヒラギノ角ゴ Pro W3","ＭＳ Ｐゴシック","Osaka",sans-selif;
    background-color: whitesmoke;
}

#Container {
    margin-left: 10px;
    margin-right: 10px;
    margin-bottom: 0px;
    margin-top: 0px;

    border-left: black solid 1px;
    border-right: black solid 1px;
    height: 100%;
    min-height:100%;
    background-color: white;
    color: black;
}

#Header {
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

#FooterContainer {
    border-top: 1px solid black;
    font-size: 10px;
    color: black;
    position:absolute;
    bottom:0px;
    height:20px;
    width:100%;
}
#Footer {
    text-align: right;
    padding-right: 10px;
    padding-top: 2px;
}

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
    <%= $module %>::DBI
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
-- t/03_dbi.t
use strict;
use warnings;
use t::Util;
use Test::More;
use <%= $module %>::DBI;

eval {
    <%= $module %>::DBI->connect('dbi:unknown:', '', '');
};
ok $@, "dies with unknown driver, automatically.";

my $dbh = <%= $module %>::DBI->connect('dbi:SQLite::memory:', '', '');
$dbh->do(q{CREATE TABLE foo (e)});
$dbh->insert('foo', {e => 3});
$dbh->do_i('INSERT INTO foo ', {e => 4});
is join(',', map { @$_ } @{$dbh->selectall_arrayref('SELECT * FROM foo ORDER BY e')}), '3,4';

subtest 'utf8' => sub {
    $dbh->do(q{CREATE TABLE bar (x)});
    $dbh->insert(bar => { x => "こんにちは" });
    my ($x) = $dbh->selectrow_array(q{SELECT x FROM bar});
    is $x, "こんにちは";
};

eval {
    $dbh->insert('bar', {e => 3});
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/<%= $module %>::DBI 's Exception/;

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

