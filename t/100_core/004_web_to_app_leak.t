use strict;
use warnings;
use utf8;
use Test::More;

our $DESTROY = 0;
our $DISPATCH = 0;

{
    package MockDB;
    sub new { bless {}, shift }
    sub DESTROY { $::DESTROY++ }
}

{
    package MyApp::Web;
    use parent qw/Amon2 Amon2::Web/;
    sub dispatch {
        my ($c) = @_;
        return $c->create_response(200, [], 'dispatch OK');
    }
    __PACKAGE__->add_trigger(
        BEFORE_DISPATCH => sub {
            my $c = shift;
            $c->{mockdb} = MockDB->new();
            if (!$::DISPATCH) {
                return $c->create_response(200, [], 'trigger OK');
            }
        }
    );
}

my $app = MyApp::Web->to_app();
{
    local $DESTROY  = 0;
    local $DISPATCH = 0;
    my $res = $app->(+{});
    is($res->[2]->[0], 'trigger OK');
    is($DESTROY, 1);
}

{
    local $DESTROY  = 0;
    local $DISPATCH = 1;
    my $res = $app->(+{});
    is($res->[2]->[0], 'dispatch OK');
    is($DESTROY, 1);
}

done_testing;

