package Amon::Config::Loader::Perl;
use strict;
use warnings;

sub load {
    my ($class, $config_class) = @_;
    my $config_dir  = $config_class->config_dir;
    my $config_name = $config_class->config_name;
    my $common_name = $config_class->common_name();

    my $common = eval { do File::Spec->catfile($config_dir, "$common_name.pl") } || {};
    my $detail = $config_name ? do File::Spec->catfile($config_dir, "$config_name.pl") : {};

    return $config_class->merge($common, $detail);
}

1;
__END__

=head1 NAME

Amon::Config::Perl - 

=head1 SYNOPSIS

    package MyApp::Config;
    use Amon::Config (
        loader     => 'Perl',
    );

    # in your script
    my $config = MyApp::Config->instance();

    # in your config/devel.pl
    +{
      'M::DB' => { dsn => 'dbi:SQLite:' }
    };
    # in your config/production.pl
    +{
      'M::DB' => { dsn => 'dbi:SQLite:database=/path/to/production.db' }
    };

=head1 DESCRIPTION


=cut

