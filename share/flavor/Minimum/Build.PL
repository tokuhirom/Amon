use strict;
use warnings;
use Module::Build;
use Module::CPANfile;

my $file = Module::CPANfile->load("cpanfile");
my $prereq = $file->prereq_specs;

my $build = Module::Build->subclass(code => <<'...'
    # Module:::Build's share_dir handling is not good for me.
    # We need to install 'tmpl' directories to '$DIST_DIR/tmpl'. But M::B doesn't support it.
    sub process_asset_files {
        my $self = shift;
        my $share_prefix = File::Spec->catdir($self->blib, qw/lib auto share dist/, '<% $dist %>');
        for my $src (@{$self->rscan_dir('tmpl')}, @{$self->rscan_dir('static')}) {
            next if -d $src;
            $self->copy_if_modified(
                from => $src,
                to_dir => File::Spec->catfile( $share_prefix )
            );
        }
    }
...
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
$build->add_build_element('asset');
$build->create_build_script();
