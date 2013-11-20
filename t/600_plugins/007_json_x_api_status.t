use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'JSON';

subtest 'default' => sub {
    my $app = do {
        package MyApp;
        use parent qw(Amon2::Web Amon2);
        __PACKAGE__->load_plugins(qw(Web::JSON));
        __PACKAGE__->new();
    };
    $app->{request} = Amon2::Web::Request->new(+{});

    my $res = $app->render_json({ status => 200 });
    is($res->code, 200);
    is($res->header('X-API-Status'), undef);
    is $res->content, '{"status":200}';
};

subtest 'set status_code_field = undef' => sub {
    my $app = do {
        package MyApp2;
        use parent qw(Amon2::Web Amon2);
        __PACKAGE__->load_plugins(
            'Web::JSON' => { status_code_field => undef }
        );
        __PACKAGE__->new();
    };
    $app->{request} = Amon2::Web::Request->new(+{});

    my $res = $app->render_json({ status => 200 });
    is($res->code, 200);
    is($res->header('X-API-Status'), undef);
    is $res->content, '{"status":200}';
};

subtest 'set status_code_field = "error"' => sub {
    my $app = do {
        package MyApp3;
        use parent qw(Amon2::Web Amon2);
        __PACKAGE__->load_plugins(
            'Web::JSON' => { status_code_field => 'error' }
        );
        __PACKAGE__->new();
    };
    $app->{request} = Amon2::Web::Request->new(+{});

    subtest 'not have a status_code_field' => sub {
        my $res = $app->render_json({});
        is($res->code, 200);
        is($res->header('X-API-Status'), undef);
        is $res->content, '{}';
    };

    subtest 'have a status_code_field' => sub {
        my $res = $app->render_json({ error => 402 });
        is($res->code, 200);
        is($res->header('X-API-Status'), '402');
        is $res->content, '{"error":402}';
    };
};

subtest 'set status_code_field = ""' => sub {
    my $app = do {
        package MyApp4;
        use parent qw(Amon2::Web Amon2);
        __PACKAGE__->load_plugins(
            'Web::JSON' => { status_code_field => '' }
        );
        __PACKAGE__->new();
    };
    $app->{request} = Amon2::Web::Request->new(+{});

    subtest 'not have a status_code_field' => sub {
        my $res = $app->render_json({});
        is($res->code, 200);
        is($res->header('X-API-Status'), undef);
        is $res->content, '{}';
    };

    subtest 'have a status_code_field' => sub {
        my $res = $app->render_json({ '' => 402 });
        is($res->code, 200);
        is($res->header('X-API-Status'), '402');
        is $res->content, '{"":402}';
    };
};

subtest 'set status_code_field = "0"' => sub {
    my $app = do {
        package MyApp5;
        use parent qw(Amon2::Web Amon2);
        __PACKAGE__->load_plugins(
            'Web::JSON' => { status_code_field => '0' }
        );
        __PACKAGE__->new();
    };
    $app->{request} = Amon2::Web::Request->new(+{});

    subtest 'not have a status_code_field' => sub {
        my $res = $app->render_json({});
        is($res->code, 200);
        is($res->header('X-API-Status'), undef);
        is $res->content, '{}';
    };

    subtest 'have a status_code_field' => sub {
        my $res = $app->render_json({ '0' => 402 });
        is($res->code, 200);
        is($res->header('X-API-Status'), '402');
        is $res->content, '{"0":402}';
    };
};

done_testing;

