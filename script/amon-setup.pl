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
use Amon;
1;
-- lib/$path/Web.pm
package [%= $module %]::Web;
use Amon::Web (
    view_class => 'MT',
);
1;
-- lib/$path/V/MT/Context.pm
package [%= $module %]::V::MT::Context;
use Amon::V::MT::Context;
1;
-- lib/$path/Web/Dispatcher.pm
% my $perlver = shift;
package [%= $module %]::Web::Dispatcher;
use Amon::Web::Dispatcher;
% if ($perlver eq '5.10') {
use feature 'switch';

sub dispatch {
    my ($class, $req) = @_;
    given ($req->path_info) {
        when ('/') {
            call("Root", 'index');
        }
        default {
            res_404();
        }
    }
}
% } else {
sub dispatch {
    my ($class, $req) = @_;
    if ($req->path_info eq '/') {
        call("Root", 'index');
    } else {
        res_404();
    }
}
% }

1;
-- lib/$path/Web/C/Root.pm
package [%= $module %]::Web::C::Root;
use Amon::Web::C;

sub index {
    render("index.mt");
}

1;
-- tmpl/index.mt
? extends 'base.mt';
? block title => 'amon page';
? block content => sub { 'hello, Amon world!' };
-- tmpl/base.mt
<!doctype html>
<html>
<head>
<title><? block title => 'Amon' ?></title>
</head>
<body>
<? block content => 'body here' ?>
</body>
</html>
-- $dist.psgi
use [%= $module %];
use [%= $module %]::Web;
[%= $module %]::Web->app("./");
-- Makefile.PL
use inc::Module::Install;
all_from "lib/[%= $path %].pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon';

WriteAll;
-- t/01_root.t
use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;

test_psgi
    app => Plack::Util::load_psgi '<?= $dist ?>.psgi',
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
    };

done_testing;
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
    _mkpath "tmpl";
    _mkpath "t";

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

