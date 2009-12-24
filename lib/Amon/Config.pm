package Amon::Config;
use strict;
use warnings;
use File::Spec;
use Amon::Util;
use Class::Singleton;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);
    return if $caller eq 'main';

    strict->import;
    warnings->import;

    my $base_class = $args{base_class} || do {
        local $_ = $caller;
        s/::Config(?:::.+)?//;
        $_;
    };
    my $loader = Amon::Util::load_class($args{loader} || 'Perl', 'Amon::Config::Loader');
    my $config_name = $args{config_name} || do {
        my $envname = Amon::Util::class2env($base_class);
        $ENV{"${envname}_CONFIG_NAME"};
    };
    my $merger = Amon::Util::load_class($args{merger}|| 'Simple', 'Amon::Config::Merger');
    my $common_name = $args{common_name} || 'common';

    no strict 'refs';
    unshift @{"${caller}::ISA"}, 'Class::Singleton';
    *{"${caller}::common_name"}   = sub { $common_name };
    *{"${caller}::config_name"}   = sub { $config_name };
    *{"${caller}::config_dir"}    = sub {
        $args{config_dir} || do {
            Amon::Util::load_class($base_class);
            File::Spec->catdir($base_class->base_dir, 'config');
        };
    };
    *{"${caller}::merge"}         = $merger->can('merge');
    *{"${caller}::_new_instance"} = sub { $loader->load($caller) };
}

1;
