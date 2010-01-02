package Amon;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Amon::Util;
use Amon::Trigger;
use 5.008001;

our $VERSION = 0.02;
{
    our $_context;
    sub context { $_context }
    sub set_context { $_context = $_[1] }
}

sub import {
    my $class = shift;

    strict->import;
    warnings->import;

    if (@_>0 && shift eq '-base') {
        my $caller = caller(0);

        no strict 'refs';
        unshift @{"${caller}::ISA"}, $class;

        my $base_dir = Amon::Util::base_dir($caller);
        *{"${caller}::base_dir"} = sub { $base_dir };
    }
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

# for CLI
sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    Amon->set_context($self);
    return $self;
}

sub config { $_[0]->{config} || +{} }

sub component {
    my ($self, $name) = @_;
    my $namespace = $self->can('base_class') ? $self->base_class : ref $self;
    my $klass = "${namespace}::$name";
    $self->{_components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{$name};
        $klass->new($config ? $config : ());
    };
}

sub model {
    my ($self, $name) = @_;
    $self->component("M::$name");
}

sub view {
    my $self = shift;
    my $name = @_ == 1 ? $_[0] : $self->default_view_class;
    $self->component("V::$name");
}

1;
__END__

=head1 NAME

Amon - lightweight web application framework

=head1 SYNOPSIS

    $ amon-setup.pl MyApp

=head1 Point

    Fast
    Easy to use

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

