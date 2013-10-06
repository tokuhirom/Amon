use strict;
use warnings;
use Module::Build;
use Module::CPANfile;

my $file = Module::CPANfile->load("cpanfile");
my $prereq = $file->prereq_specs;

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
