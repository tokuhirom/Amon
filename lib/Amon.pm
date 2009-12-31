package Amon;
use strict;
use warnings;
use Amon::Util;
use 5.008003;

our $VERSION = 0.02;
{
    our $_context;
    sub context { $_context }
    sub set_context { $_context = $_[1] }
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    strict->import;
    warnings->import;

    no strict 'refs';
    my $base_dir = Amon::Util::base_dir($caller);
    *{"${caller}::base_dir"} = sub { $base_dir };
    for my $meth (qw/new config component model view web_base request bootstrap/) {
        *{"${caller}::${meth}"} = *{"${class}::${meth}"};
    }
}

sub new {
    my ($class, %args) = @_;
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
    my $klass = "@{[ ref $self ]}::$name";
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
    my ($self, $name) = @_;
    $self->component("V::$name");
}

# web related accessors
sub web_base { $_[0]->{web_base} }
sub request  { $_[0]->{request}  }

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

