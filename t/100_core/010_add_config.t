use strict;
use warnings;
use utf8;
use Amon2::Web::Request;
use URI::Escape;
use Encode;
use Test::More;
use Amon2;

{
    package MyApp;
    use parent qw/Amon2/;
    use Test::More;
    sub load_config {+{
        'Foo' => {
            bar => 'baz',
        },
    }}
    local $SIG{__WARN__} = sub { }; # add_config method outputs deprecated warnigns
    __PACKAGE__->add_config(
        'Foo' => {
            'hoge' => 'fuga',
        },
    );
    is_deeply(__PACKAGE__->config->{'Foo'}, +{ 'hoge' => 'fuga', 'bar' => 'baz'});
    __PACKAGE__->add_config(
        'Foo' => {
            bar => 'new',
        },
    );
    is_deeply(__PACKAGE__->config->{'Foo'}, +{ 'hoge' => 'fuga', 'bar' => 'new'});
}

done_testing;
