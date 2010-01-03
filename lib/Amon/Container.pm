package Amon::Container;
use strict;
use warnings;
use Amon::Util;

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
    my $klass = "@{[ $self->base_class ]}::$name";
    $self->{_components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{$name} || +{};
        my $obj = $klass->new({context => $self, %$config});
        $obj;
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
