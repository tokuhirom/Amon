package Amon::Plugin::MobileCharset;
use strict;
use warnings;
use HTTP::MobileAgent::Plugin::Charset;
use Encode::JP::Mobile;

sub init {
    my ($class, $c, $conf) = @_;

    $c->add_method('html_content_type' => sub {
        my $ma = shift->request->mobile_agent;
        my $ct  = $ma->is_docomo ? 'application/xhtml+xml;charset=' : 'text/html;charset=';
           $ct .= $ma->can_display_utf8 ? 'utf-8' : 'Shift_JIS';
           $ct;
    });

    $c->add_method('encoding' => sub {
        shift->request->mobile_agent->encoding
    });
}

1;
__END__

=head1 NAME

Amon::Plugin::MobileCharset - Amon plugin for Japanese mobile phone's charset

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon::Web -base;

    __PACKAGE__->load_plugins(
        'MobileAgent'   => {},
        'MobileCharset' => {},
    );

=head1 DESCRIPTION

=head1 DEPENDENCIES

This module depend to L<HTTP::MobileAgent::Plugin::Charset>, L<Encode::JP::Mobile>.

And, load L<Amon::Plugin::MobileAgent> first.

=head1 SEE ALSO

L<HTTP::MobileAgent::Plugin::Charset>, L<Encode::JP::Mobile>

