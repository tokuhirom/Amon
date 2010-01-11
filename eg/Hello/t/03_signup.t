use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';
use t::Utils;

my $app = t::Utils->mk_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/signup');
$mech->content_lacks(q{<ul class="error">});
$mech->submit_form(
    form_number => 1,
    fields      => {
        'email'    => 'foo@example.com',
        'nick'     => 'john',
        'password' => 'kogaidan'
    }
);
$mech->content_contains('thanks to your registration');
$mech->get_ok('/');
$mech->submit_form(
    form_name   => 'login',
    fields      => {
        'email'    => 'foo@example.com',
        'password' => 'kogaidan'
    }
);
$mech->content_contains('Hello, john');
$mech->submit_form(
    form_name   => 'post',
    fields      => {
        'body' => 'hey'
    }
);
$mech->content_contains('hey');

done_testing;
