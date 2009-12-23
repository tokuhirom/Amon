package Amon;
use strict;
use warnings;
use 5.008001;

our $VERSION = 0.01;

our $_base;
our $_global_config;
our $_registrar;

sub import {
    my $class = shift;
    my $caller = caller(0);
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;
}

# OVERWRITABLE
sub base_dir {
    my $class = shift;
    no strict 'refs';
    ${"${class}::_base_dir"} ||= do {
        my $path = $class;
        $path =~ s!::!/!g;
        my $libpath = $INC{"$path.pm"};
        $libpath =~ s!(?:blib/)?lib/$path\.pm$!!;
        $libpath || './';
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

