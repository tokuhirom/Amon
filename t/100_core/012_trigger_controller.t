use strict;
use warnings;
use utf8;
use Test::More;

{
    package MyApp::V1;
    use parent qw/Amon2 Amon2::Web/;
    __PACKAGE__->add_trigger(
        BEFORE_DISPATCH => sub { 1 } # returns unblessed value
    );
    sub dispatch { Amon2::Web::Response->new(200, [], ['OK']) }
}

is(MyApp::V1->to_app->({})->[2]->[0], 'OK');

{
    package MyApp::V2;
    use parent qw/Amon2 Amon2::Web/;
    __PACKAGE__->add_trigger(
        BEFORE_DISPATCH => sub { # returns response object
            Amon2::Web::Response->new(200, [], ['OK2']);
        }
    );
    sub dispatch { Amon2::Web::Response->new(200, [], ['NG']) }
}
is(MyApp::V2->to_app->({})->[2]->[0], 'OK2');

done_testing;

