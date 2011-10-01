use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Minimum;

sub parent { 'Base' }
sub is_standalone { 1 }

1;
__DATA__

@@ lib/<<PATH>>.pm
package <% $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

: block load_config -> {
sub load_config {
    +{
        'Text::Xslate' => +{}
    }
}
: }

1;

@@ lib/<<PATH>>/Web.pm
package <% $module %>::Web;
use strict;
use warnings;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

: block prepare -> { }

: block dispatch -> {
# write your code here.
sub dispatch {
    my ($c) = @_;

    $c->render('index.tt');
}
: }

: block create_view -> {
# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{ };
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c        => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
        %$view_conf
    });
    sub create_view { $view }
}
: }

: block load_plugins -> { }

: block triggers -> {
# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);
: }

1;

@@ tmpl/index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title><% $module %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <% $module %>
</body>
</html>
@@ app.psgi
: cascade "!"
: around app -> {
use <% $module %>::Web;

<% $module %>::Web->to_app();
: }

@@ t/00_compile.t
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
: block modules -> {
    <% $module %>
    <% $module %>::Web
: }
);

done_testing;

__END__

=head1 NAME

Amon2::Setup::Flavor::Minimum - Amon2::Minimum flavor

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Minimum MyApp

=head1 DESCRIPTION

This is a flavor for benchmarking...

=head1 AUTHOR

Tokuhiro Matsuno

