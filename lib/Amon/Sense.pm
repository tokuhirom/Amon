package Amon::Sense;
## This is experimental!
use strict;
use warnings;
use parent 'Exporter';
use Carp ();
use File::Spec::Functions qw(catfile catdir);
use Path::Class qw(file dir);
use Try::Tiny qw(try catch);
use Encode qw/encode decode encode_utf8 decode_utf8/;
use URI;
use URI::Escape qw/uri_escape uri_unescape/;
use String::CamelCase qw/camelize decamelize/;

our @EXPORT = qw/slurp try catch catfile catdir encode decode encode_utf8 decode_utf8 file dir uri uri_escape uri_unescape escape_html camelize decamelize/;

sub import {
    my $class = shift;
    my $pkg = caller(0);

    strict->import;
    warnings->import;

    $class->export_to_level(1, $pkg, @_);
}

# my $content = slurp '<', $fname;
# my $content = slurp $fname;
sub slurp {
    if (@_ == 1) {
        open(my $fh, '<', $_[0]) or return;
        return do { local $/; <$fh> };
    } else {
        open(my $fh, @_) or return; ## no critic.
        return do { local $/; <$fh> };
    }
}

sub uri { URI->new(@_) }

{
    my %_escape_table = (
        '&'  => '&amp;',
        '>'  => '&gt;',
        '<'  => '&lt;',
        q{"} => '&quot;',
        q{'} => '&#39;'
    );
    sub escape_html {
        local $_ = $_[0];
        s!([&><"'])!$_escape_table{$1}!ge;
        $_;
    }
}

1;
