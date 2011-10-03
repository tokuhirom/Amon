package B1;

sub is_standalone { 1 }
sub web_context_path { 'lib/<<PATH>>/Web.pm' }
sub context_path     { 'lib/<<PATH>>.pm' }

1;
__DATA__
@@ lib/<<PATH>>.pm
# B1
: block load_plugins -> {
: }

@@ lib/<<PATH>>/Web.pm
# B1
: block load_plugins -> {
: }

@@ Makefile.PL
# B1
: block modules -> {
: }
