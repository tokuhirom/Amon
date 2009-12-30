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
    strict->import;
    warnings->import;
    Amon::Util::load_class($klass);
    $klass->import();
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $class;
}

sub new {
    my ($class, $conf) = @_;
    my $include_path = $conf->{include_path} || [File::Spec->catfile(Amon->context->base_dir, 'tmpl')];
    bless {include_path => $include_path}, $class;
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

sub _mt_cache_dir {
    File::Spec->catfile(File::Spec->tmpdir(), "amon.$>.$Amon::VERSION");
}

sub __load_internal {
    my ($self, $path, @params) = @_;
    if ($self->__use_cache($path)) {
        my $tmplfname = $self->_mt_cache_dir() . "/$path.c";

        open my $fh, '<', $tmplfname or die "Can't read template file: ${tmplfname}($!)";
        my $tmplsrc = do { local $/; <$fh> };
        close $fh;

        local $@;
        my $tmplcode = eval $tmplsrc; ## no critic.
        die $@ if $@;
        return $tmplcode->(@params);
    } else {
        return $self->__compile($path, @params);
    }
}

sub __compile {
    my ($self, $path, @params) = @_;

    my $mt = Text::MicroTemplate->new(
        package_name => "@{[ ref Amon->context ]}::V::MT::Context",
    );
    $self->__build_file($mt, $path);
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
    $self->__update_cache($path, $code);
    return $out;
}

sub __build_file {
    my ($self, $mt, $file) = @_;
    my $filepath = $self->resolve_tmpl_path($file) or Carp::croak("Can't find template: $file");

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

sub __update_cache {
    my ($self, $path, $code) = @_;

    my $cache_path = $self->_mt_cache_dir();
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
    my ($self, $path) = @_;
    my $cache_dir = $self->_mt_cache_dir();
    my $src = $self->resolve_tmpl_path($path) or return;
    my @orig = stat $src
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

