package Amon::Container;
# This class should not contain any Amon specific feature.
use strict;
use warnings;
use parent 'Class::Data::Inheritable';
use Amon::Util ();

__PACKAGE__->mk_classdata('_factory_map' => +{});

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless { config => +{}, %args }, $class;
}

sub config { $_[0]->{config} }

sub get {
    my ($self, $name, @args) = @_;
    $self->{components}->{$name} ||= do {
        my $config = $self->config()->{$name} || +{};
        if (my $factory = $self->_factory_map->{$name}) {
            $factory->($self, $name, $config, @args);
        } else {
            my $klass = "@{[ $self->base_name ]}::$name";
            Amon::Util::load_class($klass);
            $klass->new($config);
        }
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

