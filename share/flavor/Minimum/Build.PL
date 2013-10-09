use strict;
use warnings;
use Module::Build;
use Module::CPANfile;
use builder::MyBuilder;

my $file = Module::CPANfile->load("cpanfile");
my $prereq = $file->prereq_specs;

my $build = builder::MyBuilder->new(
    license              => 'unknown',
    dynamic_config       => 0,

    build_requires       => {
        $prereq->{build} ? %{$prereq->{build}->{requires}} : (),
        $prereq->{test} ? %{$prereq->{test}->{requires}} : (),
    },
    configure_requires   => {
        %{$prereq->{configure}->{requires}},
    },
    requires             => {
        perl => '5.008001',
        %{$prereq->{runtime}->{requires}},
    },
    script_files => [glob('script/*'), glob('bin/*')],

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
