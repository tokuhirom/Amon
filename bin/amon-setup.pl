#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw/mkpath/;
use Getopt::Long;
use Pod::Usage;
use Text::MicroTemplate ':all';

my $perlver = $] >= 5.010000 ? '5.10' : '5.8';
GetOptions(
    'perlver=s' => \$perlver,
    'help' => \my $help,
) or pod2usage(0);
pod2usage(1) if $help;

my $confsrc = <<'...';
-- lib/$name.pm
package $name;
use Amon (
  view_class => 'MT',
);
1;
-- lib/$name/V/MT/Context.pm
package $name::V::MT::Context;
use Amon::V::MT::Context;
1;
-- lib/$name/Dispatcher.pm
% my $perlver = shift;
package $name::Dispatcher;
use Amon::Dispatcher;
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
-- lib/$name/C/Root.pm
package $name::C::Root;
use Amon::C;

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
-- $name.psgi
use $name;
$name->app("./");
...

&main;exit;

sub _mkpath {
    my $d = shift;
    print "mkdir $d\n";
    mkpath $d;
}

sub main {
    my $name = shift @ARGV or pod2usage(0);
    (my $distname = $name) =~ s/::/-/g;
    mkdir $distname or die $!;
    chdir $distname or die $!;
    _mkpath "lib/$name/";
    _mkpath "lib/$name/V";
    _mkpath "lib/$name/V/MT";
    _mkpath "lib/$name/C";
    _mkpath "tmpl";

    my $conf = _parse_conf($confsrc);
    while (my ($file, $tmpl) = each %$conf) {
        $file =~ s/(\$\w+)/$1/gee;
        $tmpl =~ s/(\$name)/$1/gee;
        my $code = Text::MicroTemplate->new(
            tag_start => '[%',
            tag_end   => '%]',
            line_start => '%',
            template => $tmpl,
        )->build;
        my $res = $code->($perlver)->as_string;

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

