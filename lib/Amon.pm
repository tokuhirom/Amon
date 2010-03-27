package Amon;
use strict;
use warnings;
use 5.008001;
use Amon::Container;

our $VERSION = '0.22';
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
        unshift @{"${caller}::ISA"}, 'Amon::Container';

        my $base_dir = Amon::Util::base_dir($caller);
        *{"${caller}::base_dir"} = sub { $base_dir };

        *{"${caller}::base_name"} = sub { $caller };

        my $factory_map = {};
        *{"${caller}::_factory_map"} = sub { $factory_map };

        for my $meth (qw/bootstrap model view logger db view add_method load_plugins load_plugin/) {
            *{"${caller}::${meth}"} = *{"${class}::${meth}"};
        }


    }
}

# for CLI
sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    Amon->set_context($self);
    return $self;
}

# -------------------------------------------------------------------------
# shortcut for your laziness

sub model {
    my ($self, $name) = @_;
    $self->get("M::$name");
}

sub logger {
    my ($self) = @_;
    $self->get("Logger");
}

sub db {
    my $self = shift;
    $self->get(join('::', "DB", @_));
}

sub view {
    my $self = shift;
    my $name = @_ == 1 ? $_[0] : $self->default_view_class;
       $name = "V::$name";
    my $klass = "@{[ $self->base_name ]}::$name";
    $self->{components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{$name} || +{};
        $klass->new($self, $config);
    };
}

# -------------------------------------------------------------------------
# pluggable things

sub add_method {
    my ($class, $name, $code) = @_;
    Amon::Util::add_method($class, $name, $code);
}

sub load_plugins {
    my ($class, @args) = @_;
    for (my $i=0; $i<@args; $i+=2) {
        my ($module, $conf) = ($args[$i], $args[$i+1]);
        $class->load_plugin($module, $conf);
    }
}

sub load_plugin {
    my ($class, $module, $conf) = @_;
    $module = Amon::Util::load_class($module, 'Amon::Plugin');
    $module->init($class, $conf);
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

=head1 CLASS METHODS

=over 4

=item my $c = Amon->context();

Get the context object.

=item Amon->set_context($c)

Set your context object(INTERNAL USE ONLY).

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

