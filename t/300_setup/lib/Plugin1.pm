package Plugin1;

1;
__DATA__
@@ Makefile.PL
: cascade "!";
: after modules -> {
# Plugin1-Makefile.PL
: }

@@ <<WEB_CONTEXT_PATH>>
: cascade "!";
: after load_plugins -> {
# Plugin1-lib/My/App/Web.pm
: }

@@ <<CONTEXT_PATH>>
: cascade "!";
: after load_plugins -> {
# Plugin1-lib/My/App.pm
: }
