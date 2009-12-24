package Amon::V::MT;
use strict;
use warnings;
use Text::MicroTemplate;
use File::Spec;
use FindBin;
use Amon::Util;

our $render_context;

sub import {
    my ($class, $base) = @_;
    my $caller = caller(0);
    my $klass = "${caller}::Context"; # FIXME: configurable class name
    Amon::Util::load_class($klass);
    $klass->import();
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;
}

sub new {
    my ($class, $conf) = @_;
    bless {}, $class;
}

# entry point
sub render {
    my $class = shift;
    local $render_context = {};
    $class->__load_internal(@_);
}

# user can override this method.
sub resolve_tmpl_path {
    my ($class, $file) = @_;
    File::Spec->catfile(Amon->context->base_dir, 'tmpl', $file);
}

sub _mt_cache_dir {
    File::Spec->catfile(File::Spec->tmpdir(), "amon.$>.$Amon::VERSION");
}

sub __load_internal {
    my ($class, $path, @params) = @_;
    if (0 && $class->__use_cache($path)) {
        my $tmplfname = $class->_mt_cache_dir() . "/$path.c";

        open my $fh, '<', $tmplfname or die "Can't read template file: ${tmplfname}($!)";
        my $tmplsrc = do { local $/; <$fh> };
        close $fh;

        local $@;
        my $tmplcode = eval $tmplsrc;
        die $@ if $@;
        return $tmplcode->(@params);
    } else {
        return $class->__compile($path, @params);
    }
}

sub __compile {
    my ($class, $path, @params) = @_;

    my $mt = Text::MicroTemplate->new(
        package_name => "@{[ ref Amon->context ]}::V::MT::Context",
    );
    $class->__build_file($mt, $path);
    my $code = $class->__eval_builder($mt->code);
    my $compiled = do {
        local $SIG{__WARN__} = sub {
            print STDERR $mt->_error(shift, 4, $render_context->{caller});
        };

        my $ret = eval $code;
        die "template compilation error\n$@" if $@;
        $ret;
    };
    my $out = $compiled->(@params);
    $class->__update_cache($path, $code);
    return $out;
}

sub __build_file {
    my ($class, $mt, $file) = @_;
    my $filepath = $class->resolve_tmpl_path($file);

    open my $fh, "<:utf8", $filepath
        or Carp::croak("Can't open template file :$filepath:$!");
    my $src = do { local $/; <$fh> };
    close $fh;

    $mt->parse($src);
}

sub __eval_builder {
    my ($class, $code) = @_;
    return <<"...";
package @{[ ref Amon->context ]}\::V::MT::Context;
#line 1
sub {
    my \$out = Text::MicroTemplate::encoded_string((
        $code
    )->(\@_));
    if (my \$parent = delete \$Amon::V::MT::render_context->{extends}) {
        \$out = @{[ ref Amon->context ]}\::V::MT->__load_internal(\$parent);
    }
    \$out;
}
...
}

sub __update_cache {
    my ($class, $path, $code) = @_;

    my $cache_path = $class->_mt_cache_dir();
    foreach my $p (split '/', $path) {
        mkdir $cache_path;
        $cache_path .= "/$p";
    }
    $cache_path .= '.c';

    open my $fh, '>:utf8', $cache_path
        or die "Can't open template cache file for writing: $cache_path($!)";
    print $fh $code;
    close $fh;
}

sub __use_cache {
    my ($class, $path) = @_;
    my $cache_dir = $class->_mt_cache_dir();
    my @orig = stat $class->resolve_tmpl_path($path)
        or return;
    my @cached = stat "$cache_dir/${path}.c"
        or return;
    return $orig[9] < $cached[9];
}


1;
__END__

=head1 NAME

Amon::V::MT - Amon Text::MicroTemplate View Class

=head1 SYNOPSIS

    package MyApp::V::MT;
    use Amon::V::MT;
    1;

=head1 DESCRIPTION

=head1 SEE ALSO

L<Text::MicroTemplate>, L<Amon>

=cut

