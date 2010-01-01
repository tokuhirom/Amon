package Amon::Web::Dispatcher;
use strict;
use warnings;
use Amon::Web::Declare;
use base 'Exporter';
our @EXPORT = qw/call new/;

sub import {
    strict->import;
    warnings->import;
    Amon::Web::Declare->export_to_level(1);
    __PACKAGE__->export_to_level(1);
}

sub new { bless {}, shift }

sub call {
    my ($controller, $action, @args) = @_;
    "@{[ Amon->context->web_base ]}::C::$controller"->$action(@args);
}

1;
__END__

=head1 NAME

Amon::Web::Dispatcher - Amon Dispatcher class

=head1 SYNOPSIS

    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher;
    use 5.010;
    sub dispatch {
        my ($class, $req) = @_;
        given ([$req->method, $req->uri]) {
             when (['GET', '/']) {
                 call('Root', 'index');
             }
             when (['POST', '/post']) {
                 call('Entry', 'post');
                 # or
                 MyApp::C::Entry->post($req);
             }
             default {
                 res_404(); # return 404 response
             }
        }
    }

=head1 DESCRIPTION

This is a base class of dispatcher.

=head1 SEE ALSO

L<Amon>

=cut


