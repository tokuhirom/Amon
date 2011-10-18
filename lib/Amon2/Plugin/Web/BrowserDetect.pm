package Amon2::Plugin::Web::BrowserDetect;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';

use HTTP::BrowserDetect;

sub init {
    my ($class, $c, $conf) = @_;
    Amon2::Util::add_method(
        $c,
        'browser',
        sub {
            $_[0]->{browser} ||= HTTP::BrowserDetect->new(
                $_[0]->req->env->{'HTTP_USER_AGENT'}
            );
        },
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Amon2::Plugin::Web::BrowserDetect - HTTP::BrowserDetect plugin for Amon2

=head1 SYNOPSIS

    package MyApp::Web;
    use parent qw/MyApp Amon2::Web/;
    __PACKAGE__->load_plugins('Web::BrowserDetect');
    1;

    # in your controller
    $c->browser();

=head1 DESCRIPTION

This plugin integrates L<HTTP::BrowserDetect> and L<Amon2>.

This module adds C<< $c->browser() >> method to the context object.
The agent class is generated by C<< $c->req >>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<HTTP::BrowserDetect>, L<Amon2>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
