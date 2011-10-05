use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Minimum;

sub parent { 'Base' }
sub is_standalone { 1 }

sub web_context_path { 'lib/<<PATH>>/Web.pm' }
sub context_path { 'lib/<<PATH>>.pm' }
sub config_development_path { 'lib/<<PATH>>.pm' }
sub config_deployment_path { 'lib/<<PATH>>.pm' }
sub config_test_path { 'lib/<<PATH>>.pm' }

1;
__DATA__

@@ lib/<<PATH>>.pm
package <: $module :>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

: $plugin.context

: block load_config -> {
sub load_config {
    my $env = $ENV{PLACK_ENV} || 'development';
    if ($env eq 'development') {
        +{
            'Text::Xslate' => +{},
: block config_development -> {
: }
        }
    } elsif ($env eq 'deployment') {
        +{
            'Text::Xslate' => +{},
: block config_deployment -> {
: }
        }
    } elsif ($env eq 'test') {
        +{
            'Text::Xslate' => +{},
: block config_test -> {
: }
        }
    } else {
        die "Unknown PLACK_ENV: $env";
    }
}
: }

: block load_plugins -> {
: }

1;

@@ lib/<<PATH>>/Web.pm
package <: $module :>::Web;
use strict;
use warnings;
use parent qw/<: $module :> Amon2::Web/;
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
: include "#xslate"
: }

: block load_plugins -> { }
: $plugin.web_context

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
    <title><: $module :></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <: $module :>
</body>
</html>
@@ app.psgi
: cascade "!"
: around app -> {
use Plack::Builder;

require <: $module :>::Web;

builder {
: block middlewares -> {
: }
    <: $module :>::Web->to_app();
};
: }

@@ t/00_compile.t
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
: block modules -> {
    <: $module :>
    <: $module :>::Web
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

