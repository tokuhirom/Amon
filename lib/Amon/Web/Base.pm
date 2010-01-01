package Amon::Web::Base;
use strict;
use warnings;
use Amon::Trigger;

sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding          { 'utf-8' }

sub to_app {
    my ($class, %args) = @_;
    my $base_class = $class->base_class;

    my $dispatcher    = $class->dispatcher_class;
    my $request_class = $class->request_class;

    return sub {
        my $env = shift;

        my $req = $request_class->new($env);
        my $c = $base_class->new(
            web_base => $class,
            config   => $args{config},
            request  => $req,
        );
        local $Amon::_context = $c;
        $dispatcher->dispatch($req, $c);
        my $res = $c->response()
                    or die "response is not generated";
        return $res;
    };
}


1;
