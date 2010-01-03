package Amon;
use strict;
use warnings;
use 5.008001;
use Amon::Container;

our $VERSION = 0.02;
{
    our $_context;
    sub context { $_context }
    sub set_context { $_context = $_[1] }
}

sub import {
    my $class = shift;

    strict->import;
    warnings->import;

    if (@_>0 && shift eq '-base') {
        my $caller = caller(0);

        no strict 'refs';
        unshift @{"${caller}::ISA"}, 'Amon::Container';

        my $base_dir = Amon::Util::base_dir($caller);
        *{"${caller}::base_dir"} = sub { $base_dir };

        *{"${caller}::base_class"} = sub { $caller };
    }
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

