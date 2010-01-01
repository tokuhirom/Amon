package Amon::Web;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;
use Module::Pluggable::Object;
use Try::Tiny;
use Amon::Util;
use Amon::Trigger;

__PACKAGE__->mk_classdata( 'base_class' );
__PACKAGE__->mk_classdata( 'default_view_class' => 'MT' );
__PACKAGE__->mk_classdata( 'request_class'      => 'Amon::Web::Request' );
__PACKAGE__->mk_classdata( 'dispatcher_class' );

sub to_app {
    my ($class, %args) = @_;
    $class->call_trigger('BEFORE_SETUP');
    $class->_setup();

    my $request_class = $class->request_class;

    my $c = $class->base_class->bootstrap(
        web_base => $class,
        config   => $args{config},
    );
    $c->base_dir(); # precache
    my $dispatcher = $c->component($class->dispatcher_class || 'Web::Dispatcher');

    return sub {
        my $env = shift;
        try {
            my $req = $request_class->new($env);
            $c->{request} = $req;
            local $Amon::_context = $c;
            $dispatcher->dispatch($req, $c);
        } catch {
            if (ref $_ && ref $_ eq 'ARRAY') {
                return $_;
            } else {
                local $SIG{__DIE__} = 'default'; # do not overwrite $trace in Middleware::StackTrace
                die $_; # rethrow
            }
        }
    };
}

sub _setup {
    my $class = shift;

    # setup default var
    unless ($class->base_class) {
        $class->base_class(do {
            local $_ = $class;
            s/::Web(?:::.+)?$//;
            $_;
        });
    }
    Amon::Util::load_class($class->base_class);

    # load controllers
    Module::Pluggable::Object->new(
        'require'     => 1,
        'search_path' => ["${class}::C"],
    )->plugins;

    # load request class
    Amon::Util::load_class($class->request_class);
}

# you can overwrite this configuration stuff in child class.
sub html_content_type  { 'text/html; charset=UTF-8' }
sub encoding           { 'utf-8' }

1;
