use inc::Module::Install;

all_from 'lib/Amon2.pm';
license 'perl';

requires 'Plack'                     => 0.9927;
requires 'Try::Tiny'                 => 0.04;
requires 'Test::More'                => 0.88; # 0.88 or later is required for done_testing!
requires 'Exporter';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'parent';
requires 'UNIVERSAL::require' => 0.13;
requires 'Tfall';

# Not core, but default components.
requires 'Text::Xslate';
requires 'Text::MicroTemplate' => 0.11;
requires 'Router::Simple'            => 0.02;
requires 'Data::OptList';
requires 'Log::Dispatch';

# Amon2::Sense deps
requires 'String::CamelCase';
requires 'URI' => 1.54;
requires 'URI::Escape';
requires 'Path::Class';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon-setup.pl';
auto_include;
auto_install;
auto_set_repository;

WriteAll;
