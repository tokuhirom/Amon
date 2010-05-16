use strict;
use warnings;
use 5.12.0;
use autodie;
use Text::Xslate qw/escaped_string/;
use Path::Class;
use YAML;
use Pod::POM;
use Pod::HTMLEmbed;
use File::Copy::Recursive qw/rcopy/;
use Encode;

my $BASE = file(__FILE__)->dir->stringify;
my $OUT = "/usr/local/webapp/amon-website/";
# my $OUT = "/tmp/docs/";
my $XT = Text::Xslate->new(
    'path' => ["$BASE/tmpl/"],
    'syntax' => 'TTerse',
);

&main;exit;

sub main {
    my ($pm, $pod) = aggregate();
    render_top($pm, $pod);
    for my $fname (@$pm, @$pod) {
        render_pod($fname);
    }
    copy_assets('css');
}

sub copy_assets {
    my ($src) = @_;
    rcopy("$BASE/$src", "$OUT/$src") or die;
}

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>:utf8', $fname;
    print {$fh} $content;
    close $fh;
}

sub render_top {
    my ($pm, $pod) = @_;
    my $c = sub {
        sort { $a->{pkg} cmp $b->{pkg} } grep { $_->{pkg} } map {
            my $pkg = parse($_)->name || do {
                my $x = $_;
                $x =~ s!^lib/!!;
                $x =~ s!/!::!g;
                $x =~ s!\.pm!!;
                $x;
            };
            my $desc = parse($_)->title;
            +{
                fname => $_, desc => $desc, pkg => $pkg, ofname => fname2ofname($_),
            }
        } @_;
    };
    my $content = $XT->render( 'top.tx', {
        pm  => [ $c->(@$pm) ],
        pod => [ $c->(@$pod) ],
    } );
    write_file("$OUT/index.html", $content);
}

sub fname2ofname {
    my ($fname, ) = @_;
    $fname =~ s!^lib/!!;
    $fname =~ s!/!-!g;
    $fname;
}

sub parse {
    state %cache;
    state $parser = Pod::HTMLEmbed->new;
    my $fname = shift;
    $cache{$fname} //= $parser->load($fname);
}

sub render_pod {
    my $fname = shift;
    my $ofname = fname2ofname($fname);
    my $html = parse($fname)->body;
    my $content = $XT->render("entry.tx", {html => escaped_string(decode_utf8 $html)});
    write_file("$OUT/$ofname.html", $content);
}

sub aggregate {
    my @pm;
    my @pod;
    dir('lib')->recurse(
        callback => sub {
            my $f = shift;
            return unless -f $f;
            given ("$f") {
                when (qr/\.pm$/) {
                    push @pm, "$f";
                }
                when (qr/\.pod$/) {
                    push @pod, "$f";
                }
            }
        },
    );
    return (\@pm, \@pod)
}
