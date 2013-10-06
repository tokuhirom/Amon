%% cascade "Minimum/t/Util.pm"

%% after export -> {
    slurp
%% }

%% after functions -> {
sub slurp {
    my $fname = shift;
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    scalar do { local $/; <$fh> };
}

# initialize database
use <% $module %>;
{
    unlink 'db/test.db' if -f 'db/test.db';
    system("sqlite3 db/test.db < sql/sqlite.sql");
}
%% }
