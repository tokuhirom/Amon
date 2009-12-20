package Amon::V::MT;
use strict;
use warnings;
use Text::MicroTemplate;
use File::Spec;
use FindBin;
use UNIVERSAL::require;

our $render_context;

sub import {
    my ($class, $base) = @_;
    "${base}::V::MT::Context"->use or die $@;
}

# entry point
sub render {
    my $class = shift;
    local $render_context = {};
    __load_internal(@_);
}

# user can override this method.
sub resolve_tmpl_path {
    my $file = shift;
    File::Spec->catfile($Amon::_basedir, 'tmpl', $file);
}

sub _mt_cache_dir {
    File::Spec->catfile(File::Spec->tmpdir(), "amon.$>.$Amon::VERSION");
}

sub __load_internal {
    my ($path, @params) = @_;
    if (0 && __use_cache($path)) {
        my $tmplfname = _mt_cache_dir() . "/$path.c";

        open my $fh, '<', $tmplfname or die "Can't read template file: ${tmplfname}($!)";
        my $tmplsrc = do { local $/; <$fh> };
        close $fh;

        local $@;
        my $tmplcode = eval $tmplsrc;
        die $@ if $@;
        return $tmplcode->(@params);
    } else {
        return __compile($path, @params);
    }
}

sub __compile {
    my ($path, @params) = @_;

    my $mt = Text::MicroTemplate->new(
        package_name => "${Amon::_base}::V::MT::Context",
    );
    __build_file($mt, $path);
    my $code = __eval_builder($mt->code);
    my $compiled = do {
        local $SIG{__WARN__} = sub {
            print STDERR $mt->_error(shift, 4, $render_context->{caller});
        };

        my $ret = eval $code;
        die "template compilation error\n$@" if $@;
        $ret;
    };
    my $out = $compiled->(@params);
    __update_cache($path, $code);
    return $out;
}

sub __build_file {
    my ($mt, $file) = @_;
    my $filepath = resolve_tmpl_path($file);

    open my $fh, "<:utf8", $filepath
        or Carp::croak("Can't open template file :$filepath:$!");
    my $src = do { local $/; <$fh> };
    close $fh;

    $mt->parse($src);
}

sub __eval_builder {
    my $code = shift;
    return <<"...";
package $Amon::_base\::V::MT::Context;
#line 1
sub {
    my \$out = Text::MicroTemplate::encoded_string((
        $code
    )->(\@_));
    if (my \$parent = delete \$Amon::V::MT::render_context->{extends}) {
        \$out = Amon::V::MT::__load_internal(\$parent);
    }
    \$out;
}
...
}

sub __update_cache {
    my ($path, $code) = @_;

    my $cache_path = _mt_cache_dir();
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
    my ($path) = @_;
    my $cache_dir = _mt_cache_dir();
    my @orig = stat resolve_tmpl_path($path)
        or return;
    my @cached = stat "$cache_dir/${path}.c"
        or return;
    return $orig[9] < $cached[9];
}


1;
