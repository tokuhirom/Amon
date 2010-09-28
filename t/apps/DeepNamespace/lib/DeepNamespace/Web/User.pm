package DeepNamespace::Web::User;
use strict;
use parent qw/DeepNamespace Amon2::Web/;
use Tiffany;
use DeepNamespace::Web::User::Dispatcher;
use Module::Find;
useall 'DeepNamespace::Web::User::C';
sub create_view {
    my $conf = __PACKAGE__->config->{'Text::MicroTemplate::Extended'} || die;
    Tiffany->load( 'Text::MicroTemplate::Extended', $conf);
}
sub dispatch { DeepNamespace::Web::User::Dispatcher->dispatch(shift) }
1;
