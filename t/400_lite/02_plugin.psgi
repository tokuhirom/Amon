use strict;
use warnings;
use Amon2::Lite;

__PACKAGE__->load_plugin('Web::JSON');

get '/' => sub {
    my $c = shift;
    $c->render_json({ok => 1});
};

__PACKAGE__->to_app();
