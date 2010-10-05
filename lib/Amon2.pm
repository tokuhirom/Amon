package Amon2;
use strict;
use warnings;
use 5.008001;
use Amon2::Util ();
use Plack::Util ();
use Data::OptList ();
use parent qw/Class::Data::Inheritable/;
use Carp ();

our $VERSION = '0.44';
{
    our $_context;
    sub context { $_context }
    sub set_context { $_context = $_[1] }
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless { %args }, $class;
}

# for CLI
sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    Amon2->set_context($self);
    return $self;
}

sub base_dir {
    my $proto = ref $_[0] || $_[0];
    my $base_dir = Amon2::Util::base_dir($proto);
    Amon2::Util::add_method($proto, 'base_dir', sub { $base_dir });
    $base_dir;
}

sub load_config { die "Abstract base method" }
sub config {
    my $class = shift;
       $class = ref $class || $class;
    die "Do not call Amon2->config() directly." if __PACKAGE__ eq $class;
    no strict 'refs';
    my $config = $class->load_config();
    *{"$class\::config"} = sub { $config }; # class cache.
    return $config;
}

sub add_config {
    my ($class, $key, $hash) = @_; $hash or Carp::croak("missing args: \$hash");
    $class->config->{$key} = +{
        %{$class->config->{$key} || +{}},
        %{$hash},
    };
}

# -------------------------------------------------------------------------
# pluggable things

sub load_plugins {
    my ($class, @args) = @_;
    for my $opt (@{Data::OptList::mkopt(\@args)}) {
        my ($module, $conf) = ($opt->[0], $opt->[1]);
        $class->load_plugin($module, $conf);
    }
}

sub load_plugin {
    my ($class, $module, $conf) = @_;
    $module = Plack::Util::load_class($module, 'Amon2::Plugin');
    $module->init($class, $conf);
}


1;
__END__

=head1 NAME

Amon2 - lightweight web application framework

=head1 SYNOPSIS

    $ amon-setup.pl MyApp

=head1 Point

    Fast
    Easy to use

=head1 CLASS METHODS

=over 4

=item my $c = Amon2->context();

Get the context object.

=item Amon2->set_context($c)

Set your context object(INTERNAL USE ONLY).

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

