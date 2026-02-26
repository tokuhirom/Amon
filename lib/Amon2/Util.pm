package Amon2::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;
use MIME::Base64 ();
use Crypt::SysRandom qw(random_bytes);
use Carp ();

our @EXPORT_OK = qw/add_method random_string/;

sub add_method {
    my ($klass, $method, $code) = @_;
    no strict 'refs';
    *{"${klass}::${method}"} = $code;
}

sub base_dir($) {
    my $path = shift;
    $path =~ s!::!/!g;
    if (my $libpath = $INC{"$path.pm"}) {
        $libpath =~ s!\\!/!g; # win32
        $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
        File::Spec->rel2abs($libpath || './');
    } else {
        File::Spec->rel2abs('./');
    }
}

sub random_string {
    my $len = shift;

    if ($len < 27) {
        Carp::cluck("Amon2::Util::random_string: Length too short. You should use 27+ bytes for security reason.");
    }

    my $src_len = int($len / 3 * 4) + 4;
    my $buf = random_bytes($src_len);
    my $result = MIME::Base64::encode_base64($buf, '');
    $result =~ tr|+/=|\-_|d; # make it url safe
    return substr($result, 0, $len);
}

1;
__END__

=head1 DESCRIPTION

This is a utility class for Amon2. Do not use this directly.
