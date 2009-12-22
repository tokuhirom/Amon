package Amon::CLI;
use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/run/;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    my $base_class = $args{base_class} or die "missing configuration: base_class";

    no strict 'refs';
    *{"${caller}::base_class"} = sub { $base_class };
    unshift @{"${caller}::ISA"}, $class;
}

sub setup {
    my ($class, $conf) = @_;
    my $base_class = $class->base_class();
    ${"${base_class}::_global_config"} = $conf;
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::CLI;
    use Amon::CLI (
        base_class => 'MyApp',
    );

    # in your script.pl
    use MyApp::CLI;
    my $conf = {
        'M::DB' => {
            dsn => 'dbi:SQLite:'
        }
    };
    MyApp::CLI->setup(
        $conf,
    );

    my ($row) = model("DB")->get(user => 1);
    print $row->name, "\n";

