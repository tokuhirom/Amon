use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 1,
    build_requires       => {
        'Test::Requires' => '0.06',
        'Test::More'     => '0.98',
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        'perl'                       => '5.008001',
        'Exporter'                   => '0',
        'parent'                     => '0.223',
        'Try::Tiny'                  => '0.06',
        'URI'                        => '1.54',
        'Plack'                      => '0.9982', # sanity check to remove newlines from headers
        'Plack::Session'             => '0', # required in Amon2::Web
        ($] < 5.009_005 ?  ('MRO::Compat' => '0.11') : ()),

        # Not core, but default components.
        'Text::Xslate'               => '1.6001', # fixed possibly memory leaks
        'Router::Simple::Sinatraish' => '0.02',
        'Router::Simple'             => '0.06',
    },
    no_index    => { 'directory' => [ 'eg', 'inc', 't', 'xt' ] },
    name        => 'Amon2',
    module_name => 'Amon2',

    script_files => ['script/amon2-setup.pl'],

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
