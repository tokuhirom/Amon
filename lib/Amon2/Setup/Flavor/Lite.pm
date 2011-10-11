use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Lite;
use parent qw/Amon2::Setup::Flavor/;

sub run {
    my ($self) = @_;

    $self->write_file('app.psgi', <<'...');
use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
use Amon2::Lite;

# put your configuration here
sub config {
    +{
    }
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);

# load plugins
__PACKAGE__->load_plugins(
    'Web::CSRFDefender',
);

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/|/robot\.txt$|/favicon.ico$)},
        root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::ReverseProxy';
	enable 'Plack::Middleware::Session';

    __PACKAGE__->to_app();
};

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <met charst="utf-8">
    <title><% $module %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <% $module %>
</body>
</html>
...

    $self->write_file('Makefile.PL', <<'...');
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => '<% $module %>',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'app.psgi',
    PREREQ_PM     => {
        'Amon2'                           => '<% $amon2_version %>',
        'Text::Xslate'                    => '1.4001',
        'Text::Xslate::Bridge::TT2Like'   => '0.00008',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'Time::Piece'                     => '1.20',
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
...

    $self->write_file('t/Util.pm', <<'...');
package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;

our @EXPORT = qw//;

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;                       
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

1;
...

    $self->write_file('t/01_root.t', <<'...');
use strict;
use warnings;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'app.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
...

    $self->write_file('xt/03_pod.t', <<'...');
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
...
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Lite - Amon2::Lite flavor

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Lite MyApp

=head1 DESCRIPTION

This is a flavor for project using Amon2::Lite.

=head1 AUTHOR

Tokuhiro Matsuno
