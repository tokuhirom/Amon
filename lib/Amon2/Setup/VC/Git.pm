package Amon2::Setup::VC::Git;
use strict;
use warnings;
use utf8;
use File::Temp qw(tempfile);

sub new {
    bless {}, $_[0];
}

sub do_import {
    my ($self) = @_;

    unless ($self->_is_git_available('git')) {
        warn "There is no git command.\n";
        return;
    }

    !system("git init") or die $?;
    !system("git add .") or die $?;
    !system(q{git commit -m "initial import"}) or die $?;
}

sub _is_git_available {
    my ($self) = @_;

    if ($^O eq 'MSWin32') {
        no warnings;
        !system('git --version 2>&1 > NUL');
    } else {
        my $pid = fork();
        die "Cannot fork: $!" if !defined $pid;
        if ($pid) { # parent
            waitpid($pid, 0);
            require POSIX;
            POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?)==0 ? 1 : 0;
        } else { # child
            my ($logfh, $logfile) = tempfile(UNLINK => 1);
            open STDOUT, '>', $logfile or die "$!";
            open STDERR, '>&STDOUT' or die "$!";
            no warnings;
            exec('git', '--version');
            exit(9);
        }
    }
}

1;

