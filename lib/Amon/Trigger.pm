package Amon::Trigger;
use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/add_trigger call_trigger get_trigger_code/;

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
    my @code = $class->get_trigger_code($hook);
    for my $code (@code) {
        $code->(@args);
    }
}

sub get_trigger_code {
    my ($class, $hook) = @_;
    no strict 'refs';
    my @code;
    if (ref $class) {
        push @code, @{ $class->{_trigger} || [] };
    }
    push @code, @{${"${class}::_trigger"}->{$hook} || []};
    return @code;
}

1;
