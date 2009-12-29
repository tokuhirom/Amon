use inc::Module::Install;

all_from 'lib/Amon.pm';
license 'perl';

requires 'Module::Pluggable::Object' => 3.9;
requires 'Plack::Request'            => 0.09;
requires 'Plack'                     => 0.9023;
requires 'Text::MicroTemplate'       => 0.10;
requires 'Try::Tiny'                 => 0.02;
requires 'Exporter';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon-setup.pl';
auto_include;
auto_install;
auto_set_repository;

WriteAll;
