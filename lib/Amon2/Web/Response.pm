package Amon2::Web::Response;
use strict;
use warnings;
use parent qw/Plack::Response/;
use Plack::Util::Accessor qw/wait_for_events/;


1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Web::Response - web response class for Amon2

=head1 DESCRIPTION

This is response class for Amon2.

This class is child class of L<Plack::Response>.

There is no extension for now, but I'm using this class for future plan.
