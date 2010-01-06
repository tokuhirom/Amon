package Amon::Factory::DataModel;
use strict;
use warnings;
use Amon::Util;

sub create {
    my ($class, $c, $klass, $conf) = @_;
    Amon::Util::load_class($klass);
    my $obj = $klass->new();
    if (my $module = $conf->{module}) {
        $module = Amon::Util::load_class($module, 'Data::Model::Driver');
        my $driver = $module->new(%{ $conf->{config} || +{} });
        $obj->set_base_driver($driver);
    }
    return $obj;
}

1;
