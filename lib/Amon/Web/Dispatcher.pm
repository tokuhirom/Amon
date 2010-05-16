package Amon::Web::Dispatcher;
use strict;
use warnings;
use Amon::Web::Declare;
use base 'Exporter';
our @EXPORT = qw/call/;

sub import {
    strict->import;
    warnings->import;
    Amon::Web::Declare->export_to_level(1);
    __PACKAGE__->export_to_level(1);
}

sub call {
    my ($controller, $action, @args) = @_;
    "@{[ ref Amon->context ]}::C::$controller"->$action(@args);
}

1;
__END__

=head1 NAME

Amon::Web::Dispatcher - Amon Dispatcher class

=head1 SYNOPSIS

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher;
    sub dispatch {
        my ($class, $req) = @_;
        if ($req->method eq 'GET' && $req->uri eq '/') {
            return MyApp::Web::C::Root->index($req);
        } elsif ($req->method eq 'POST' && $req->uri eq '/post') {
            return MyApp::Web::C::Entry->post($req);
        } else {
            return res_404(); # 404 not found
        }
    }

=head1 DESCRIPTION

This is a base class of dispatcher.

=head1 SEE ALSO

L<Amon>

=cut


