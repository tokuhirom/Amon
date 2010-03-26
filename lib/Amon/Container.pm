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
    my ($self, $name, @args) = @_;
    $self->{components}->{$name} ||= do {
        my $config = $self->config()->{$name} || +{};
        if (my $factory = $self->get_factory($name)) {
            $factory->($self, $name, $config, @args);
        } else {
            my $klass = "@{[ $self->base_name ]}::$name";
            Amon::Util::load_class($klass);
            $klass->new($config);
        }
    };
}

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

sub add_factory {
    my ($class, $target, $factory) = @_;
    if (not ref $factory) {
        # This feature will remove.
        Carp::carp("Factory class was deprecated. Will remove.");
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

# -------------------------------------------------------------------------

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

Amon::Container - Amon container class

=head1 SYNOPSIS

  package MyApp;
  use Amon -base;

=head1 DESCRIPTION

This is container class for Amon.

=head1 METHODS

=head2 CONTAINER METHODS

=over 4

=item my $c = MyApp->new(config => \%conf);

create new instance of MyApp.

=item my $c = MyApp->bootstrap(config => \%conf);

create new instance of MyApp, and call Amon->set_context($c).

=item $c->config()

Get the configuration.

=item $c->get($name)

Get the instance of component named $name.

=item $c->model($name)

Shortcut method for $c->get("M::$name").

=item $c->db()

Short cut method for $c->get("DB")

=item $c->view($name)

Create instance of component named "V::$name".

=item __PACKAGE__->add_factory($target, $factory)

    __PACKAGE__->add_factory(
        'DB' => 'DBI',
    );
    __PACKAGE__->add_factory(
        'MyComponent' => sub {
            my ($self, $name, $config, @args) = @_;
            ...
        },
    );


register factory class to container.

After this, $c->get($target) return the return value of $factory->create($target, $c->config->{$name}).

=item $c->get_factory($target)

Get the factory class for $target.

=back

=head1 PLUGIN RELATED METHODS

=over 4

=item $c->add_method($name => $code)

add method to $c.

=item $c->load_plugin($name => $conf)

load plugin with configuration $conf.

=item $c->load_plugins($name => $conf, $name => $conf, ...)

load plugins.

=back

=cut

