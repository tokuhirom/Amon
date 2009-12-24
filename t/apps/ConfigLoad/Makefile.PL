use inc::Module::Install;
all_from "lib/ConfigLoad.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon';

WriteAll;
