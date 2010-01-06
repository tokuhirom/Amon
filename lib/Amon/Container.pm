package Amon::Container;
use strict;
use warnings;
use Amon::Util ();

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

sub get {
    my ($self, $name) = @_;
    my $klass = "@{[ $self->base_class ]}::$name";
    $self->{components}->{$klass} ||= do {
        my $config = $self->config()->{$name} || +{};
        if (my $factory = $self->get_factory($name)) {
            $factory->($self, $klass, $config);
        } else {
            Amon::Util::load_class($klass);
            $klass->new($config);
        }
    };
}

sub model {
    my ($self, $name) = @_;
    $self->get("M::$name");
}

sub db {
    my $self = shift;
    $self->get(join('::', "DB", @_));
}

sub view {
    my $self = shift;
    my $name = @_ == 1 ? $_[0] : $self->default_view_class;
       $name = "V::$name";
    my $klass = "@{[ $self->base_class ]}::$name";
    $self->{components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{$name} || +{};
        $klass->new($self, $config);
    };
}

sub add_method {
    my ($class, $name, $code) = @_;
    Amon::Util::add_method($class, $name, $code);
}

sub add_factory {
    my ($class, $target, $factory) = @_;
    if (not ref $factory) {
        my $factory_class = Amon::Util::load_class($factory, 'Amon::Factory');
        $factory = sub { $factory_class->create(@_) };
    }
    $class->_factory_map->{$target} = $factory;
}
sub get_factory {
    my ($class, $target) = @_;
    $class = ref $class if ref $class;
    $class->_factory_map->{$target};
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
