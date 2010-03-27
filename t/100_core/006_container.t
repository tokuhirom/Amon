use strict;
use warnings;
use Test::More;

{
    package MyApp;
    use parent 'Amon::Container';
    __PACKAGE__->add_factory('DB' => sub {
        my ($c, $klass, $conf) = @_;
        return "YES $conf";
    });
}

my $app = MyApp->new(config => {
    'DB' => 'MYSETTINGS',
});
is $app->get('DB'), 'YES MYSETTINGS';

done_testing;
