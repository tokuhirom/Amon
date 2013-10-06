package Amon2::Setup::Flavor::Minimum;
use strict;
use warnings FATAL => 'all';
use utf8;
use parent qw(Amon2::Setup::Flavor);

sub run {
    my ($self) = @_;

    $self->render_file('lib/<<PATH>>.pm',                   'Minimum/lib/__PATH__.pm');
    $self->render_file("tmpl/index.tx",                     'Minimum/tmpl/index.tx');
    $self->render_file($self->psgi_file,                    'Minimum/script/server.pl');
    $self->render_file('lib/<<PATH>>/Web.pm',               'Minimum/lib/__PATH__/Web.pm');
    $self->render_file('lib/<<PATH>>/Web/View.pm',          'Minimum/lib/__PATH__/Web/View.pm');
    $self->render_file('lib/<<PATH>>/Web/ViewFunctions.pm', 'Minimum/lib/__PATH__/Web/ViewFunctions.pm', {
        'context_class' => 'Amon2',
    });
    $self->render_file('Build.PL', 'Minimum/Build.PL');
    $self->render_file('t/Util.pm', 'Minimum/t/Util.pm');
    $self->render_file('t/00_compile.t', 'Minimum/t/00_compile.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file('t/01_root.t', 'Minimum/t/01_root.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file('t/02_mech.t', 'Minimum/t/02_mech.t', {
        psgi_file => $self->psgi_file,
    });
    $self->render_file('xt/01_pod.t', 'Minimum/xt/01_pod.t');

    $self->create_cpanfile();
}

sub create_cpanfile {
    my ($self, $deps) = @_;
    $deps->{'Module::Functions'} ||= 2;

    $self->write_file('cpanfile', <<'...', {deps => $deps});
requires 'perl', '5.008001';
requires 'Amon2', '<% $amon2_version %>';
requires 'Text::Xslate', '1.6001';
requires 'Starlet', '0.20';
<% for $deps.keys() -> $v { -%>
requires <% sprintf("%-33s", "'" ~ $v ~ "'") %>, '<% $deps[$v] %>';
<% } -%>

on 'configure' => sub {
   requires 'Module::Build', '0.38';
   requires 'Module::CPANfile', '0.9010';
};

on 'test' => sub {
   requires 'Test::More', '0.98';
};
...
}

sub psgi_file {
    my $self = shift;
    'script/' . lc($self->{dist}) . '-server';
}

sub show_banner {
    my $self = shift;

    printf <<'...', $self->psgi_file;
--------------------------------------------------------------

Setup script was done! You are ready to run the skelton.

You need to install the dependencies by:

    > carton install

And then, run your application server:

    > carton exec perl -Ilib %s

--------------------------------------------------------------
...
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Minimum - Minimalistic flavor suitable for benchmarking

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Minimum MyApp

=head1 DESCRIPTION

This is a flavor for benchmarking...

=head1 AUTHOR

Tokuhiro Matsuno
