use inc::Module::Install;
all_from "lib/TTApp.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon';

WriteAll;
