use strict;
use warnings;
use Test::More;
use Amon2::Web::Response;
use Amon2::Web::Response::Callback;

my $res = Amon2::Web::Response->new(200, [], 'ok');
$res->content_type('text/html');
$res->status(403);
$res->body('hoge');
isa_ok $res, 'Amon2::Web::Response', 'method chain';
is_deeply $res->finalize(), [403, ['Content-Type' => 'text/html'], ['hoge']];

test_callback_finalize(
  expected => [ 403, [ 'Content-Type' => 'text/html' ], [ 'hoge' ] ],
  given => [ 403, [ 'Content-Type' => 'text/html' ], [ 'hoge' ] ],
);

test_callback_finalize(
  dies => 1,
  given => [ 403, [ 'Content-Type' => "text/html\r\n" ], [ 'hoge' ] ],
);

test_callback_finalize(
  dies => 1,
  given => [
    403,
    [ 'Content-Type' => 'text/html', 'Content-Length' => "42\r\n" ],
    [ 'hoge' ],
  ],
);

done_testing;

sub test_callback_finalize {
  my (%params) = @_;

  my $dies = delete $params{dies};
  my $expected = delete $params{expected};
  my $given = delete $params{given};

  my $cb_res = Amon2::Web::Response::Callback->new(
    code => sub {
      my ($respond) = @_;
      $respond->($given);
    },
  );

  my ($got) = eval { $cb_res->finalize->(sub { @_ }) };
  if ($dies) {
    ok $@, 'Error-expected operation returned a value.';
  } else {
    is_deeply $got, $expected;
  }
}
