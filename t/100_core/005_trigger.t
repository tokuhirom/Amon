use strict;
use warnings;
use Test::More;

{
    package MyApp;
    use Amon2::Trigger;

    sub new { bless { BAR => 0 }, shift }

    __PACKAGE__->add_trigger(
        FOO => sub {
            my $self = shift;
            $self->{FOO} = 1;
        },
        BAR => sub {
            my $self = shift;
            $self->{BAR} += 1;
        },
    );
}

subtest 'normal' => sub {
    my $app = MyApp->new();
    $app->call_trigger('FOO');
    $app->add_trigger('BAZ', sub { $_[0]->{BAZ} = 1 });
    $app->call_trigger('BAZ');
    $app->add_trigger('BAR', sub { $_[0]->{BAR} += 1 });
    $app->call_trigger('BAR');
    is $app->{FOO}, 1;
    is $app->{BAR}, 2;
    is $app->{BAZ}, 1;
};

# -------------------------------------------------------------------------

{
    package MyApp::Parent;
    use Amon2::Trigger;

    sub new { bless { BAR => 0 }, shift }
    __PACKAGE__->add_trigger(
        f => sub { $_[0]->{p}++ }
    );

    package MyApp::Child;
    our @ISA = qw/MyApp::Parent/;

    __PACKAGE__->add_trigger(
        f => sub { $_[0]->{c}++ }
    );
}

subtest 'inheritance' => sub {
    my $c = MyApp::Child->new();
    $c->call_trigger('f');
    ok $c->{p}, "called parent's hook";
    ok $c->{c};
};

done_testing;

