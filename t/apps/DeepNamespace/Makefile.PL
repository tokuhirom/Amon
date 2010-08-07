use inc::Module::Install;
all_from "lib/DeepNamespace.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';

WriteAll;
