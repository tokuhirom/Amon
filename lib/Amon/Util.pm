package Amon::Util;
use strict;
use warnings;

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

1;
