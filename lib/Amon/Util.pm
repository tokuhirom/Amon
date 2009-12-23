package Amon::Util;
use strict;
use warnings;

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

sub class2env {
    my $class = shift || '';
    $class =~ s/::/_/g;
    return uc($class);
}

1;
