package Amon2::Setup::VC::Git;
use strict;
use warnings;
use utf8;
use File::Which qw(which);

sub new {
    bless {}, $_[0];
}

sub do_import {
    my ($self) = @_;

    unless (which('git')) {
        warn "There is no git command.\n";
        return;
    }

    !system("git init") or die $?;
    !system("git add .") or die $?;
    !system(q{git commit -m "initial import"}) or die $?;
}

1;

