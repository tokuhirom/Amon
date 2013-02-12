use strict;
use warnings;
use utf8;
use Test::More;

{
    package Foo;
    use parent qw(Amon2);
    use Amon2::LocalContext;
}

subtest 'simple set context' => sub {
    is(Foo->context(), undef);
    my $c = Foo->new();
    Foo->set_context($c);
    is(Foo->context(), $c, 'context was set');
    is(Amon2->context(), undef, 'global context does not set');
    Foo->set_context(undef); # teardown
};

subtest 'context_guard' => sub {
    is(Foo->context(), undef);
    my $c = Foo->new();
    {
        my $guard = $c->context_guard();
        is(Foo->context(), $c, 'context was set');
        is(Amon2->context(), undef, 'global context does not set');
    }
    is(Foo->context(), undef, 'context was gone');
    is(Amon2->context(), undef, 'global context does not set');
};

subtest 'bootstrap' => sub {
    is(Foo->context(), undef);
    my $c = Foo->bootstrap();
    is(Foo->context(), $c, 'context was set');
    is(Amon2->context(), undef, 'global context does not set');
};

done_testing;

