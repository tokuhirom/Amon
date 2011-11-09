package Amon2::Plugin::Web::NoCache;
use strict;
use warnings;

sub init {
    my ($class, $c, $conf) = @_;

    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ($self, $res) = @_;
            $res->header( 'Pragma'        => 'no-cache' );
            $res->header( 'Cache-Control' => 'no-cache' );
        },
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::NoCache - NoCache(DEPRECATED)

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugins('Web::NoCache');

=head1 DESCRIPTION

This plugin adds following headers by AFTER_DISPATCH hook.

    Pragma: no-cache
    Cache-Control: no-cache

This is very useful if your application don't want to cache by client side.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Amon2>

