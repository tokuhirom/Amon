package Amon;
use strict;
use warnings;
use Amon::Util;
use 5.008001;
use File::Spec;

our $VERSION = 0.01;

our $_base;
our $_global_config;
our $_registrar;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    my $config_class = $args{config_class} || "${class}::Config";
    Amon::Util::load_class($config_class);

    no strict 'refs';
    *{"${caller}::config_class"}       = sub { $config_class };
    unshift @{"${caller}::ISA"}, $class;
}

# OVERWRITABLE
sub base_dir {
    my $class = shift;
    no strict 'refs';
    ${"${class}::_base_dir"} ||= do {
        my $path = $class;
        $path =~ s!::!/!g;
        if (my $libpath = $INC{"$path.pm"}) {
            $libpath =~ s!(?:blib/)?lib/$path\.pm$!!;
            File::Spec->rel2abs($libpath || './');
        } else {
            File::Spec->rel2abs('./');
        }
    };
}

1;
__END__

=head1 NAME

Amon - lightweight web application framework

=head1 SYNOPSIS

    $ amon-setup.pl MyApp

=head1 Point

    Fast
    Easy to use

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

