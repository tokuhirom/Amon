use inc::Module::Install;

all_from 'lib/Amon2.pm';
license 'perl';

requires 'Plack'      => 0.9943;
requires 'Try::Tiny'  => 0.06;
requires 'Test::More' => 0.88;     # 0.88 or later is required for done_testing!
requires 'Exporter'   => 5.64;
requires 'Class::Data::Inheritable' => 0.08;
requires 'parent'                   => 0.223;
requires 'Module::Find'             => 0.10;
requires 'URI'                      => 1.54;
requires 'URI::Escape'              => 3.30;
requires 'Data::OptList'            => 0.106;
requires 'Tiffany' => 0.02;

# Not core, but default components.
requires 'Text::Xslate'               => 0.1056;
requires 'Text::MicroTemplate'        => 0.15;
requires 'Router::Simple'             => 0.06;
requires 'Router::Simple::Sinatraish' => 0.02;
requires 'Log::Dispatch'              => 2.26;

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon-setup.pl';
auto_include;
auto_set_repository;

WriteAll;
