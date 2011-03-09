use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::AuthorTests;

all_from 'lib/Amon2.pm';
license 'perl';

requires(
    'Plack'         => 0.9943,
    'Try::Tiny'     => 0.06,
    'Test::More'    => 0.96,     # 0.96 or later is required for better testing.
    'Exporter'      => 5.64,
    'parent'        => 0.223,
    'Module::Find'  => 0.10,
    'URI'           => 1.54,
    'URI::Escape'   => 3.30,
    'Data::OptList' => 0.106,
    'MRO::Compat'   => 0,
);

# Not core, but default components.
requires(
    'Text::Xslate'                  => 1.0012,
    'Text::Xslate::Bridge::TT2Like' => '0.00007',
    'Text::MicroTemplate'        => 0.15,    # TODO: remove dependency on T::MT.
    'Router::Simple'             => 0.06,
    'Router::Simple::Sinatraish' => 0.02,
    'HTML::FillInForm::Lite'     => 1.09,
    'HTTP::Session'              => 0.41,
    'Plack::Middleware::ReverseProxy' => 0,
);

# Optional components
recommends 'Test::WWW::Mechanize::PSGI';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon2-setup.pl';
auto_include;
auto_set_repository;
no_index directory => 'eg';

WriteAll;
