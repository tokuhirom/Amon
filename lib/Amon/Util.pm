package Amon::Util;
use strict;
use warnings;
use base qw/Exporter/;
use File::Spec;

our @EXPORT = qw/add_method load_class/;

# taken from Plack::Util, because this method will use by CLI.
{
    my $loaded;
    sub load_class {
        my($class, $prefix) = @_;

        if ($prefix) {
            unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
                $class = "$prefix\::$class";
            }
        }
        return if $loaded->{$class}++;

        my $file = $class;
        $file =~ s!::!/!g;
        require "$file.pm"; ## no critic

        return $class;
    }
}

sub add_method {
    my ($klass, $method, $code) = @_;
    no strict 'refs';
    *{"${klass}::${method}"} = $code;
}

sub class2env {
    my $class = shift || '';
    $class =~ s/::/_/g;
    return uc($class);
}

sub base_dir($) {
    my $path = shift;
    $path =~ s!::!/!g;
    if (my $libpath = $INC{"$path.pm"}) {
        $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
        File::Spec->rel2abs($libpath || './');
    } else {
        File::Spec->rel2abs('./');
    }
}

1;
__END__

=head1 NAME

Amon::Util - Amon Utility Class

=head1 DESCRIPTION

This is a utility functions for L<Amon>.

=head1 FUNCTIONS

=over 4

=item Amon::Util::load_class($class, [$prefix])

  my $class = Amon::Util::load_class($class [, $prefix ]);

Constructs a class name and C<require> the class. Throws an exception
if the .pm file for the class is not found, just with the built-in                    C<require>.

If C<$prefix> is set, the class name is prepended to the C<$class>
unless C<$class> begins with C<+> sign, which means the class name is already fully qualified.

  my $class = Amon::Util::load_class("Foo");                   # Foo  my $class = Plack::Util::load_class("Baz", "Foo::Bar");       # Foo::Bar::Baz
  my $class = Amon::Util::load_class("+XYZ::ZZZ", "Foo::Bar"); # XYZ::ZZZ

=item Amon::Util::class2env

Returns the environment name for class.

    MyApp becomes MyApp
    My::App becomes MY_APP

=back

=head1 THANKS TO

load_class is taken from L<Plack::Util>.

class2env is taken from L<Catalyst::Utils>.

=head1 SEE ALSO

L<Catalyst::Utils>, L<Plack::Util>

=cut

