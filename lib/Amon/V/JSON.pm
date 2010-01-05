package Amon::V::JSON;
use strict;
use warnings;
use JSON ();
use Scalar::Util ();

sub new {
    my ($class, $c, $conf) = @_;
    my $self = bless {
        callback_param => 'callback',
        context => $c,
        %$conf,
    }, $class;
    Scalar::Util::weaken($self->{context});
    return $self;
}

sub render {
    my ($self, $stuff) = @_;
    return JSON::encode_json($stuff);
}

sub make_response {
    my ($self, $src) = @_;

    my $json = $self->render($src);

    my $req = $self->{context}->request;
    my $ua = $req->header('User-Agent') || '';

    my $content_type = do {
        if ($ua =~ /Opera/) {
            'application/x-javascript; charset=utf-8';
        } else {
            'application/json; charset=utf-8';
        }
    };

    my $output;
    ## add UTF-8 BOM if the client is Safari ### XXXX
    if ($ua =~ m/Safari/) {
        $output = "\xEF\xBB\xBF";
    }
    my $cb = _validate_callback_param($req->param($self->{callback_param}) || '');
    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    return $self->{context}->response_class->new(
        200,
        [
            'Content-Length' => length($json),
            'Content-Type'   => $content_type,
        ],
        [$json]
    );
}

sub _validate_callback_param {
    $_[0] =~ /^[a-zA-Z0-9\.\_\[\]]+$/ ? $_[0] : undef;
}

1;
