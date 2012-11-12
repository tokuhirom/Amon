use strict;
use warnings FATAL => 'all';
use utf8;

package Amon2::Setup::Flavor::Minimum;
use parent qw(Amon2::Setup::Flavor);

sub run {
    my ($self) = @_;

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

sub load_config {
    +{
        'Text::Xslate' => +{}
    }
}

1;
...


    $self->write_templates();

    $self->create_web_pms();

    $self->create_makefile_pl();

    $self->write_file('t/00_compile.t', <<'...');
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
);

done_testing;
...

    $self->write_file('t/01_root.t', <<'...');
use strict;
use warnings;
use utf8;
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

    $self->create_t_02_mech_t();

    $self->create_t_util_pm();

    $self->write_file('xt/01_pod.t', <<'...');
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
...
}

sub create_web_pms {
    my ($self) = @_;

    $self->write_file('lib/<<PATH>>/Web.pm', <<'...', { xslate => $self->create_view() });
package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

# write your code here.
sub dispatch {
    my ($c) = @_;

    $c->render('index.tt');
}

<% $xslate %>

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
        $res->header( 'X-Frame-Options' => 'DENY' );
    },
);

1;
...
}

sub create_t_02_mech_t {
    my ($self, $more) = @_;
    $more ||= '';

    $self->write_file('t/02_mech.t', <<'...' . $more . "\ndone_testing();\n");
use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = Plack::Util::load_psgi 'app.psgi';

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');

...
}

sub create_view {
    my $self = shift;

    $self->render_string(<<'...', @_);
# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), '<% $tmpl_path ? $tmpl_path : 'tmpl' %>') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::Star' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            static_file => do {
                my %static_file_cache;
                sub {
                    my $fname = shift;
                    my $c = Amon2->context;
                    if (not exists $static_file_cache{$fname}) {
                        my $fullpath = File::Spec->catfile($c->base_dir(), $fname);
                        $static_file_cache{$fname} = (stat $fullpath)[9];
                    }
                    return $c->uri_for($fname, { 't' => $static_file_cache{$fname} || 0 });
                }
            },
        },
        %$view_conf
    });
    sub create_view { $view }
}
...
}

sub psgi_header {
    <<'...';
use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
...
}

sub create_t_util_pm {
    my ($self, $exports, $more) = @_;
    $exports ||= [];
    $more ||= '';

    $self->write_file('t/Util.pm', <<'...' . $more . "\n1;\n", {exports => $exports});
package <% '' %>t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
    if ($ENV{PLACK_ENV} eq 'deployment') {
        die "Do not run a test script on deployment environment";
    }
}
use File::Spec;
use File::Basename;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'extlib', 'lib', 'perl5'));
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));
use parent qw/Exporter/;
use Test::More 0.98;

our @EXPORT = qw(<% exports.join(' ') %>);

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

...

}

sub create_makefile_pl {
    my ($self, $deps) = @_;

    $self->write_file('Build.PL', <<'...', {deps => $deps});
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->subclass(
    code => q{
        sub ACTION_install {
            die "Do not install web application.\n";
        }

        # do not make blib.
        sub ACTION_code {
            my $self = shift;
            $self->depends_on('config_data');
        }

        # run prove
        sub ACTION_test {
            my $self = shift;
            my $tests = $self->find_test_files;

            require App::Prove;
            my $prove = App::Prove->new();
            $prove->process_args('-l', @$tests);
            $prove->run();
        }
    }
)->new(
    license              => 'unknown',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.008001',
        'Amon2'                           => '<% $amon2_version %>',
        'Text::Xslate'                    => '1.5006',
<% FOR v IN deps.keys() -%>
        <% sprintf("%-33s", "'" _ v _ "'") %> => '<% deps[v] %>',
<% END -%>
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => '<% $module %>',
    module_name => '<% $module %>',
    author        => 'Some Person <person@example.com>',
    dist_abstract => 'A web site based on Amon2',

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 0,
    create_license => 0,
);
$build->create_build_script();
...
}

sub write_templates {
    my ($self, $base) = @_;
    $base ||= 'tmpl';

    $self->write_file("$base/index.tt", <<'...');
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
...

    $self->write_file('app.psgi', <<'...', {header => $self->psgi_header});
<% header %>
use <% $module %>::Web;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static');
    <% $module %>::Web->to_app();
};
...
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Minimum - Amon2::Minimum flavor

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Minimum MyApp

=head1 DESCRIPTION

This is a flavor for benchmarking...

=head1 AUTHOR

Tokuhiro Matsuno
