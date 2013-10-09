%% cascade "Minimum/script/server.pl"

%% override load_modules -> {
use <% $module %>::Admin;
use Plack::App::File;
use Plack::Session::Store::DBI;
use DBI;
%% }

%% override app -> {
use 5.010_001;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
my $app = builder {
    enable 'Plack::Middleware::Auth::Basic',
        authenticator => sub { $_[0] eq 'admin' && $_[1] eq 'admin' };
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '..', 'static', 'admin');
    enable 'Plack::Middleware::ReverseProxy';
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                state $db_config = <% $module %>->config->{DBI} || die "Missing configuration for DBI";
                DBI->connect( @$db_config )
                    or die $DBI::errstr;
            }
        );

    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, '..', 'static', 'admin'))->to_app();
    mount '/' => <% $module %>::Admin->to_app();
};
%% }
