package Amon2::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;
use MIME::Base64 ();
use Digest::SHA ();
use Time::HiRes;
use POSIX ();
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

our $URANDOM_FH;

# $URANDOM_FH is undef if there is no /dev/urandom
open $URANDOM_FH, '<:raw', '/dev/urandom'
    or do {
    undef($URANDOM_FH);
    warn "Cannot open /dev/urandom: $!.";
};

sub random_string {
    my $len = shift;

    # 27 is the sha1_base64() length.
    if ($len < 27) {
        Carp::cluck("Amon2::Util::random_string: Length too short. You should use 27+ bytes for security reason.");
    }

    if ($URANDOM_FH) {
        my $src_len = POSIX::ceil($len/3.0*4.0);
        # Generate session id from /dev/urandom.
        my $read = read($URANDOM_FH, my $buf, $src_len);
        if ($read != $src_len) {
            die "Cannot read bytes from /dev/urandom: $!";
        }
        my $result = MIME::Base64::encode_base64($buf, '');
        $result =~ tr|+/=|\-_|d; # make it url safe
        return substr($result, 0, $len);
    } else {
        # It's weaker than above. But it's portable.
        my $out = '';
        while (length($out) < $len) {
            my $sha1 = Digest::SHA::sha1_base64(rand() . $$ . {} . Time::HiRes::time());
            $sha1 =~ tr|+/=|\-_|d; # make it url safe
            $out .= $sha1;
        }
        return substr($out, 0, $len);
    }
}

1;
__END__

=head1 DESCRIPTION

This is a utility class for Amon2. Do not use this directly.
