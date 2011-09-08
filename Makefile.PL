use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::AuthorTests;

all_from 'lib/Amon2.pm';
license 'perl';

requires(
    'Plack'         => 0.9982,   # sanity check to remove newlines from headers
    'Try::Tiny'     => 0.06,
    'Test::More'    => 0.98,     # 0.98 or later is required for better testing.
    'Exporter'      => 5.64,
    'parent'        => 0.223,
    'Module::Find'  => 0.10,
    'URI'           => 1.54,
    'URI::Escape'   => 3.30,
    'Data::OptList' => 0.106,
    'MRO::Compat'   => 0,
	'Data::Section::Simple' => 0, # for ::Lite
	'HTTP::Date'                      => 6,
);

# Not core, but default components.
requires(
    'Text::Xslate'                  => 1.4001,
    'Text::Xslate::Bridge::TT2Like' => '0.00008',
    'Router::Simple'             => 0.06,
    'Router::Simple::Sinatraish' => 0.02,
    'HTML::FillInForm::Lite'     => 1.09,
    'HTTP::Session'              => 0.41,
    'Plack::Middleware::ReverseProxy' => 0,
	'JSON'                            => 2,
	'HTTP::Status'                    => '6.00',
);

# Optional components
recommends 'Test::WWW::Mechanize::PSGI';

test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t';
recursive_author_tests('xt');
install_script 'script/amon2-setup.pl';
auto_set_repository;
no_index directory => 'eg';

WriteAll;
