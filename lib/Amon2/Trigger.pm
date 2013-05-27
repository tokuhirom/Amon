package Amon2::Trigger;
use strict;
use warnings;
use parent qw/Exporter/;
use Scalar::Util ();
use if $] >= 5.009_005, 'mro';
use if $] < 5.009_005, 'MRO::Compat';

our @EXPORT = qw/add_trigger call_trigger get_trigger_code/;

sub add_trigger {
    my ($class, %args) = @_;

    if (ref $class) {
        while (my ($hook, $code) = each %args) {
            push @{$class->{_trigger}->{$hook}}, $code;
        }
    } else {
        no strict 'refs';
        while (my ($hook, $code) = each %args) {
            push @{${"${class}::_trigger"}->{$hook}}, $code;
        }
    }
}

sub call_trigger {
    my ($class, $hook, @args) = @_;
    my @code = $class->get_trigger_code($hook);
    for my $code (@code) {
        $code->($class, @args);
    }
}

sub get_trigger_code {
    my ($class, $hook) = @_;
    my @code;
    if (Scalar::Util::blessed($class)) {
        push @code, @{ $class->{_trigger}->{$hook} || [] };
        $class = ref $class;
    }
    no strict 'refs';
    my $klass = ref $class || $class;
    for (@{mro::get_linear_isa($class)}) {
        push @code, @{${"${_}::_trigger"}->{$hook} || []};
    }
    return @code;
}

1;
__END__

=head1 NAME

Amon2::Trigger - Trigger system for Amon2

=head1 SYNOPSIS

    package MyClass;
    use parent qw/Amon2::Trigger/;

    __PACKAGE__->add_trigger('Foo');
    __PACKAGE__->call_trigger('Foo');

=head1 DESCRIPTION

This is a trigger system for Amon2. You can use this class for your class using trigger system.

=head1 METHODS

=over 4

=item C<< __PACKAGE__->add_trigger($name:Str, \&code:CodeRef) >>

=item C<< $obj->add_trigger($name:Str, \&code:CodeRef) >>

You can register the callback function for the class or object.

When you register callback code on object, the callback is only registered to object, not for class.

I<Return Value>: Not defined.

=item C<< __PACKAGE__->call_trigger($name:Str); >>

=item C<< $obj->call_trigger($name:Str); >>

This method calls all callback code for $name.

I<Return Value>: Not defined.

=item C<< __PACKAGE__->get_trigger_code($name:Str) >>

=item C<< $obj->get_trigger_code($name:Str) >>

You can get all of trigger code from the class and ancestors.

=back

=head1 FAQ

=over 4

=item WHY DON'T YOU USE L<Class::Trigger>?

L<Class::Trigger> does not support get_trigger_code.

=back
