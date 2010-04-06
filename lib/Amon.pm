package Amon;
use strict;
use warnings;
use 5.008001;
use Amon::Container;
use UNIVERSAL::require;

our $VERSION = '0.41';
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
        my %args = @_;

        no strict 'refs';
        unshift @{"${caller}::ISA"}, 'Amon::Base';

        my $base_dir = Amon::Util::base_dir($caller);
        *{"${caller}::base_dir"} = sub { $base_dir };

        *{"${caller}::base_name"} = sub { $caller };

        if (my $config_loader = $args{config_loader_class}) {
            $config_loader->use or die $@;
            *{"${caller}::config_loader_class"} = sub { $config_loader };
        }
    }
}

package Amon::Base;
use parent 'Amon::Container';

sub new {
    my $class = shift;
    if ($class->can('config_loader_class')) {
        unshift @_, 'config' => $class->config_loader_class->load();
    }
    $class->SUPER::new(@_);
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

