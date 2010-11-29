use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::AuthorTests;

all_from 'lib/Amon2.pm';
license 'perl';

requires 'Plack'      => 0.9943;
requires 'Try::Tiny'  => 0.06;
requires 'Test::More' => 0.88;     # 0.88 or later is required for done_testing!
requires 'Exporter'   => 5.64;
requires 'parent'                   => 0.223;
requires 'Module::Find'             => 0.10;
requires 'URI'                      => 1.54;
requires 'URI::Escape'              => 3.30;
requires 'Data::OptList'            => 0.106;
requires 'Tiffany' => 0.02;
requires 'local::lib';

# Not core, but default components.
requires 'Text::Xslate'               => 0.1056;
requires 'Text::Xslate::Bridge::TT2Like' => '0.00007';
requires 'Text::MicroTemplate'        => 0.15; # TODO: remove dependency on T::MT.
requires 'Router::Simple'             => 0.06;
requires 'Router::Simple::Sinatraish' => 0.02;

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
