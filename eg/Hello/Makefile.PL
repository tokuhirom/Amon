use inc::Module::Install;
all_from "lib/Hello.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';
requires 'Plack::Middleware::ReverseProxy';
requires 'HTML::FillInForm::Lite';
requires 'Time::Piece';

requires 'DBIx::Skinny';
requires 'DBIx::Skinny::Schema::Loader';

recursive_author_tests('xt');

WriteAll;
