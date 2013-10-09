package <% $package // $module ~ "::Web::ViewFunctions" %>;
use strict;
use warnings;
use utf8;
use parent qw(Exporter);
use Module::Functions;
use File::Spec;

our @EXPORT = get_public_functions();

sub commify {
    local $_  = shift;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}

sub c { <% $module %>->context() }
sub uri_with { <% $module %>->context()->req->uri_with(@_) }
sub uri_for { <% $module %>->context()->uri_for(@_) }

{
    my %static_file_cache;
    sub static_file {
        my $fname = shift;
        my $c = <% $module %>->context;
        if (not exists $static_file_cache{$fname}) {
            my $fullpath = File::Spec->catfile($c->base_dir(), $fname);
            $static_file_cache{$fname} = (stat $fullpath)[9];
        }
        return $c->uri_for(
            $fname, {
                't' => $static_file_cache{$fname} || 0
            }
        );
    }
}

1;
