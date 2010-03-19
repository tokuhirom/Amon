use inc::Module::Install;

all_from 'lib/Amon.pm';
license 'perl';

requires 'Module::Pluggable::Object' => 3.9;
requires 'Plack::Request'            => 0.09;
requires 'Plack'                     => 0.9027;
requires 'Text::MicroTemplate'       => 0.11;
requires 'Try::Tiny'                 => 0.02;
requires 'Test::More'                => 0.88; # 0.88 or later is required for done_testing!
requires 'Router::Simple'            => 0.02;
requires 'String::CamelCase';
requires 'Exporter';
requires 'Class::Accessor::Fast';
requires 'parent';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon-setup.pl';
auto_include;
auto_install;
auto_set_repository;

WriteAll;
