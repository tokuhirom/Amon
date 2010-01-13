package Amon::V::TemplateBase;
use strict;
use warnings;

sub make_response {
    my $self = shift;
    my $c = $self->{context};
    my $html = $self->render(@_);
       $html = Encode::encode($c->encoding, $html);
    my $content_type = $c->html_content_type();
    return $c->response_class->new(
        200,
        [
            'Content-Type'   => $content_type,
            'Content-Length' => length($html)
        ],
        $html
    );
}

1;
