package Hello::Web;
use strict;
use warnings;
use parent qw/Hello Amon2::Web/;

# load all controller classes
use Module::Find ();
Module::Find::useall("Hello::Web::C");

# custom classes
use Hello::Web::Request;
use Hello::Web::Response;
sub create_request  { Hello::Web::Request->new($_[1]) }
sub create_response { shift; Hello::Web::Response->new(@_) }

# dispatcher
use Hello::Web::Dispatcher;
sub dispatch {
    return Hello::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Tiffany::Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || die "missing configuration for Text::Xslate";
    my $view = Tiffany::Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
        %$view_conf
    });
    sub create_view { $view }
}

# load plugins
# __PACKAGE__->load_plugins('Web::FillInFormLite');
# __PACKAGE__->load_plugins('Web::NoCache');

1;
