use inc::Module::Install;

all_from 'lib/Amon.pm';
license 'perl';

requires 'Module::Pluggable::Object';
requires 'Plack::Request';
requires 'Plack';
requires 'Text::MicroTemplate';
requires 'Try::Tiny';
requires 'UNIVERSAL::require';
requires 'Exporter';

tests 't/*.t t/*/*.t t/*/*/*.t';

WriteAll;
