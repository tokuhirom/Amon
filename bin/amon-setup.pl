use strict;
use warnings;
use File::Path qw/mkpath/;

my $confsrc = <<'...';
-- lib/$name.pm
package $name;
use Amon;
1;
-- lib/$name/V/Context.pm
package $name::V::Context;
use Amon::V::Context;
1;
-- lib/$name/Dispatcher.pm
package $name::Dispatcher;
use HTTPx::Dispatcher;
connect '' => {controller => 'Root', action => 'index'};
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
    _mkpath "lib/$name/C";
    _mkpath "tmpl";

    my $conf = _parse_conf($confsrc);
    while (my ($file, $tmpl) = each %$conf) {
        $file =~ s/(\$\w+)/$1/gee;
        $tmpl =~ s/(\$\w+)/$1/gee;

        print "writing $file\n";
        open my $fh, '>', $file or die "Can't open file($file):$!";
        print $fh $tmpl;
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

