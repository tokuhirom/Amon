use inc::Module::Install;

all_from 'lib/Amon.pm';
license 'perl';

requires 'Module::Pluggable::Object';
requires 'Plack::Request';
requires 'Plack';
requires 'Text::MicroTemplate';
requires 'Try::Tiny';
requires 'Exporter';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
install_script 'script/amon-setup.pl';
auto_include;
auto_install;
auto_set_repository;

WriteAll;
