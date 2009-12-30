package Amon::V::MT;
use strict;
use warnings;
use Text::MicroTemplate;
use File::Spec;
use FindBin;
use Amon::Util;
use Try::Tiny;
require Amon;
use constant { # bitmask
    CACHE_FILE      => 1,
    CACHE_MEMORY    => 2,
    CACHE_NO_CHECK  => 4,
};

our $render_context;
our $_MEMORY_CACHE;

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);
    my $klass = "${caller}::Context"; # FIXME: configurable class name
    strict->import;
    warnings->import;
    my $default_cache_dir  = $args{default_cache_dir} || do {
        (my $key = $caller) =~ s/::/-/g;
        File::Spec->catfile(File::Spec->tmpdir(), "amon.$>.$Amon::VERSION.$key");
    };
    try {
        Amon::Util::load_class($klass);
    } catch {
        unless (/^Can't locate /) {
            die $_;
        }
    };
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;
    *{"${caller}::default_cache_dir"} = sub { $default_cache_dir };
}

sub new {
    my ($class, $conf) = @_;
    my $include_path = $conf->{include_path} || [File::Spec->catfile(Amon->context->base_dir, 'tmpl')];
       $include_path = [$include_path] unless ref $include_path;

    bless {
        include_path => $include_path,
        cache_dir    => $conf->{cache_dir} || $class->default_cache_dir,
        cache_mode   => exists($conf->{cache_mode}) ? $conf->{cache_mode} : CACHE_FILE,
    }, $class;
}

# entry point
sub render {
    my $self = shift;
    local $render_context = {
        c => $self,
    };
    $self->__load_internal(@_);
}

# user can override this method.
sub resolve_tmpl_path {
    my ($self, $file) = @_;
    for my $inc (@{$self->{include_path}}) {
        my $path = File::Spec->catfile($inc, $file);
        return $path if -f $path;
    }
    return;
}

sub __load_internal {
    my ($self, $path, @params) = @_;
    my $cache_mode = $self->{cache_mode};

    if (($cache_mode & CACHE_MEMORY) && ($cache_mode & CACHE_NO_CHECK) && (my $code = $_MEMORY_CACHE->{ref $self}->{$path}->[0])) {
        # This branch is high-priority. That requires high-performance, person use this!
        return $code->(@params);
    }

    my $filepath = $self->resolve_tmpl_path($path) or Carp::croak("Can't find template '$path' from " . join(', ', map { qq{'$_'} } @{$self->{include_path}}));
    my @filepath_stat = stat($filepath) or Carp::croak("Can't find template: $filepath: $!");
    my $filepath_mtime = $filepath_stat[9];
    if (($cache_mode & CACHE_MEMORY) && $self->_has_fresh_memory_cache($path, $filepath_mtime)) {
        return $_MEMORY_CACHE->{ref $self}->{$path}->[0]->(@params);
    } elsif (($cache_mode & CACHE_FILE) && $self->_has_fresh_file_cache($path, $filepath_mtime)) {
        my $tmplfname = $self->{cache_dir} . "/$path.c";

        open my $fh, '<', $tmplfname or die "Can't read template file: ${tmplfname}($!)";
        my $tmplsrc = do { local $/; <$fh> };
        close $fh;

        local $@;
        my $tmplcode = eval $tmplsrc; ## no critic.
        die $@ if $@;
        return $tmplcode->(@params);
    } else {
        return $self->__compile($path, $filepath, $filepath_mtime, @params);
    }
}

sub __compile {
    my ($self, $path, $filepath, $filepath_mtime, @params) = @_;

    my $mt = Text::MicroTemplate->new(
        package_name => "@{[ ref Amon->context ]}::V::MT::Context",
    );
    $self->_build_file($mt, $filepath);
    my $code = $self->__eval_builder($mt->code);
    my $compiled = do {
        local $SIG{__WARN__} = sub {
            print STDERR $mt->_error(shift, 4, $render_context->{caller});
        };

        my $ret = eval $code; ## no critic.
        die "template compilation error\n$@" if $@;
        $ret;
    };
    my $out = $compiled->(@params);
    if ($self->{cache_mode} & CACHE_MEMORY) {
        $_MEMORY_CACHE->{ref $self}->{$path} = [
            $compiled,
            $filepath_mtime,
        ];
    } elsif ($self->{cache_mode} & CACHE_FILE) {
        $self->_update_file_cache($path, $code);
    }
    return $out;
}

sub _build_file {
    my ($self, $mt, $filepath) = @_;

    open my $fh, "<:utf8", $filepath
        or Carp::croak("Can't open template file :$filepath:$!");
    my $src = do { local $/; <$fh> };
    close $fh;

    $mt->parse($src);
}

sub __eval_builder {
    my ($self, $code) = @_;
    return <<"...";
package @{[ ref Amon->context ]}\::V::MT::Context;
#line 1
sub {
    my \$out = Text::MicroTemplate::encoded_string((
        $code
    )->(\@_));
    if (my \$parent = delete \$Amon::V::MT::render_context->{extends}) {
        \$out = \$Amon::V::MT::render_context->{c}->__load_internal(\$parent);
    }
    \$out;
}
...
}

sub _update_file_cache {
    my ($self, $path, $code) = @_;

    my $cache_dir = $self->{cache_dir};
    foreach my $p (split '/', $path) {
        mkdir $cache_dir;
        $cache_dir .= "/$p";
    }
    $cache_dir .= '.c';

    # TODO: flock required?
    open my $fh, '>:utf8', $cache_dir
        or die "Can't open template cache file for writing: $cache_dir($!)";
    print $fh $code;
    close $fh;
}

sub _has_fresh_memory_cache {
    my ($self, $path, $filepath_mtime) = @_;
    my $cache_mtime = $_MEMORY_CACHE->{ref $self}->{$path}->[1]
            or return;
    return $filepath_mtime == $cache_mtime;
}

sub _has_fresh_file_cache {
    my ($self, $path, $filepath_mtime) = @_;
    return 1 if $self->{cache_mode} & CACHE_NO_CHECK;

    my @cached = stat "$self->{cache_dir}/${path}.c"
        or return;
    return $filepath_mtime < $cached[9];
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

