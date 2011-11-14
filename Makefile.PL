use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::AuthorTests;

all_from 'lib/Amon2.pm';
license 'perl';

requires(
    'Plack'         => 0.9982,   # sanity check to remove newlines from headers
    'Try::Tiny'     => 0.06,
    'Exporter'      => 0,
    'parent'        => 0.223,
    'URI'           => 1.54,
	'File::Copy::Recursive' => '0.38',
	'Plack::Session' => 0, # required in Amon2::Web
);

requires( 'MRO::Compat' => '0.11' ) if $] < 5.009_005;

# Not core, but default components.
requires(
    'Text::Xslate'                  => 1.5006,
    'Router::Simple'             => 0.06,
    'Router::Simple::Sinatraish' => 0.02,
);

# Optional components

test_requires 'Test::Requires' => 0.06;
test_requires 'Test::More'     => 0.98;     # 0.98 or later is required for better testing.

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon2-setup.pl';
auto_set_repository;
no_index directory => 'eg';

WriteAll;
