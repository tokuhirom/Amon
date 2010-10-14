package Amon2::Plugin::Web::MobileCharset;
use strict;
use warnings;
use HTTP::MobileAgent::Plugin::Charset;
use Encode::JP::Mobile;
use Amon2::Util;

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method($c, 'html_content_type' => sub {
        my $ma = shift->mobile_agent;
        my $ct  = $ma->is_docomo ? 'application/xhtml+xml;charset=' : 'text/html;charset=';
           $ct .= $ma->can_display_utf8 ? 'utf-8' : 'Shift_JIS';
           $ct;
    });

    Amon2::Util::add_method($c, 'encoding' => sub {
        shift->mobile_agent->encoding
    });
}

1;
__END__

=head1 NAME

Amon2::Plugin::Web::MobileCharset - Amon2 plugin for Japanese mobile phone's charset

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web -base;

    __PACKAGE__->load_plugins(
        'Web::MobileAgent',
        'Web::MobileCharset',
    );

=head1 DESCRIPTION

=head1 DEPENDENCIES

This module depend to L<HTTP::MobileAgent::Plugin::Charset>, L<Encode::JP::Mobile>.

And, load L<Amon2::Plugin::MobileAgent> first.

=head1 SEE ALSO

L<HTTP::MobileAgent::Plugin::Charset>, L<Encode::JP::Mobile>

