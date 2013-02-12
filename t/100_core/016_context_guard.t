use strict;
use warnings;
use utf8;
use Test::More;


subtest 'unit test' => sub {
{
    package C;
    sub new {
        my $class = shift;
        bless {@_}, $class;
    }
    sub DEMOLISH { }
    sub x { shift->{x} }
}
    my $x = C->new(x => 3);
    my $guard = Amon2::ContextGuard->new(C->new(x => 4), \$x);
    is($x->x, 4);
    undef $guard;
    is($x->x, 3);
};

subtest 'with Amon2' => sub {
    {
        package MyApp;
        use parent qw/Amon2/;
    }

    my $c = MyApp->new();
    my $guard = $c->context_guard();
    ok(Amon2->context);
    ok(MyApp->context);
    isa_ok(Amon2->context, 'MyApp');
};

done_testing;

