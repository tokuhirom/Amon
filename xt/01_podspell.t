use strict;
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;

my $spell_cmd;
foreach my $path (split(/:/, $ENV{PATH})) {
    -x "$path/spell"  and $spell_cmd="spell", last;
    -x "$path/ispell" and $spell_cmd="ispell -l", last;
    -x "$path/aspell" and $spell_cmd="aspell list", last;
}
plan skip_all => "no spell/ispell/aspell" unless $spell_cmd;

set_spell_cmd($spell_cmd);

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Tokuhiro Matsuno
Test::TCP
tokuhirom
AAJKLFJEF
GMAIL
COM
Tatsuhiko
Miyagawa
Kazuhiro
Osawa
lestrrat
typester
cho45
charsbar
coji
clouder
gunyarakun
hio_d
hirose31
ikebe
kan
kazeburo
daisuke
maki
TODO
kazuhooku
FAQ
Amon2
DBI
PSGI
URL
XS
env
.pm
CSS
TBD
HTML
JSON
init
MyApp
plugins
CPAN
ORM
RDBMS
SQL
SQLite
bitmask
URI
HTTP
Amon
TTerse
cpanm
irc
org
CSRF
hasegawayosuke
hasegawayosuke's
JSONP
NoCache
API
Sinatra-ish
Str
callback
Xslate
app
psgi
