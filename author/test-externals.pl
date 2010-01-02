#!perl -w
use strict;
use FindBin qw($Bin);
use autodie;

my @dist = (
    'Inamode13'   => q{git://github.com/tokuhirom/Inamode13.git},
    'NoPaste'     => q{git://github.com/tokuhirom/p5-OreOre-NoPaste.git},
);

my $distdir = 'externals';

chdir $Bin;
mkdir $distdir if not -e $distdir;

$ENV{ANY_MOOSE} = 'Mouse';

while(my($name, $repo) = splice @dist, 0, 2){
    chdir "$Bin/$distdir";

    print "Go $name ($repo)\n";

    if(!(-e "$name")){
        system "git clone $repo $name";
        chdir $name;
    }
    else{
        chdir $name;
        system "git pull";
    }

    print "$^X Makefile.PL\n";
    system("$^X Makefile.PL 2>&1 |tee ../$name.log");

    print "make\n";
    system("make 2>&1 >>../$name.log");

    print "make test\n";
    system("make test 2>&1 |tee -a ../$name.log")
}
