use strict;
use warnings;
use utf8;
use Test::More;

$INC{"My/Plugin/$_.pm"}++ for 1..3;
my @conf;
{
    package My::Plugin;

    sub init {
        my ( $class, $c, $conf ) = @_;
        push @conf, [ $class, $c, $conf ];
    }

    package My::Plugin::1;
    use parent -norequire, qw(My::Plugin);

    package My::Plugin::2;
    use parent -norequire, qw(My::Plugin);

    package My::Plugin::3;
    use parent -norequire, qw(My::Plugin);
}

{
	package MyApp;
	use parent qw(Amon2);
	__PACKAGE__->load_plugins(
		'+My::Plugin::1',
		'+My::Plugin::2' => +{ opt => 2 },
		'+My::Plugin::3',
	);
}
is_deeply(
    \@conf,
    [
        [ 'My::Plugin::1', 'MyApp', undef ],
        [ 'My::Plugin::2', 'MyApp', { 'opt' => 2 } ],
        [ 'My::Plugin::3', 'MyApp', undef ]
    ]
);

done_testing;

