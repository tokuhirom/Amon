package Amon::Util::Loader;
# some code taken from Module::Pluggable::Fast.
# M::P::* things are useful, but it is targetted for *Pluggable* things.
# I want just for loading controller classes.
use strict;
use warnings;
use UNIVERSAL::require;
use File::Find ();
use File::Basename;
use File::Spec::Functions qw/splitdir catdir abs2rel/;

sub _find_packages {
    my $search = shift;

    my @files = ();

    my $wanted = sub {
        return unless $File::Find::name =~ /\.pm$/;
        ( my $path = $File::Find::name ) =~ s#^\\./##;
        push @files, $path;
    };

    File::Find::find( { no_chdir => 1, wanted => $wanted }, $search );

    return @files;
}

sub load_all {
    my ($searchpath) = @_;

    foreach my $dir ( exists $INC{'blib.pm'} ? grep { /blib/ } @INC : @INC ) {
        my $sp = catdir( $dir, ( split /::/, $searchpath ) );
        next unless ( -e $sp && -d $sp ); # /path/to/MyApp/C/
        foreach my $file ( _find_packages($sp) ) {
            my ( $name, $directory ) = fileparse $file, qr/\.pm/;
            $directory = abs2rel $directory, $sp;
            my $plugin = join '::', splitdir catdir $searchpath,
                $directory, $name;
            $plugin->require;
            my $error = $UNIVERSAL::require::ERROR;
            die qq/Couldn't load "$plugin", "$error"/ if $@;
        }
    }
}

1;
