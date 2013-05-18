requires 'Exporter';
requires 'Plack', '0.9982';
requires 'Plack::Session';
requires 'Router::Simple', '0.14';
requires 'Router::Simple::Sinatraish', '0.02';
requires 'Text::Xslate', '1.6001';
requires 'Try::Tiny', '0.06';
requires 'URI', '1.54';
requires 'parent', '0.223';
requires 'perl', '5.008001';

on build => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires', '0.06';
};
