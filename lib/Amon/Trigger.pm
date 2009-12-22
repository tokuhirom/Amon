package Amon::Trigger;
use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/add_trigger call_trigger/;

sub add_trigger {
    my ($class, $hook, $code) = @_;
    no strict 'refs';
    if (ref $class) {
        push @{$class->{_trigger}->{$hook}}, $code;
    } else {
        push @{${"${class}::_trigger"}->{$hook}}, $code;
    }
}

sub call_trigger {
    my ($class, $hook, @args) = @_;
    no strict 'refs';
    my @code;
    if (ref $class) {
        push @code, @{ $class->{_trigger} || [] };
    }
    push @code, @{${"${class}::_trigger"}->{$hook} || []};
    for my $code (@code) {
        $code->(@args);
    }
}

1;
