package Amon::M::DataModel;
use strict;
use warnings;
use base qw/Data::Model/;
use Data::Model;
use Amon::Util;

sub new {
    my ($class, $conf) = @_;
    my $self = bless {}, $class;
    if (my $module = $conf->{module}) {
        $module = Amon::Util::load_class($module, 'Data::Model::Driver');
        my $driver = $module->new(%{ $conf->{config} || +{} });
        $self->set_base_driver($driver);
    }
    $self;
}

1;
