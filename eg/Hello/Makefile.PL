use inc::Module::Install;
all_from "lib/Hello.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';
recursive_author_tests('xt');

WriteAll;
