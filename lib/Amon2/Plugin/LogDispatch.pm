package Amon2::Plugin::LogDispatch;
use strict;
use warnings;
use Log::Dispatch ();
use Plack::Util qw//;
use Data::OptList qw//;
use Amon2::Util ();

sub init {
    my ($class, $c, $config) = @_;

    my $conf = $c->config->{'Log::Dispatch'} || die "missing configuration for LogDispatch plugin(\$c->config->{'Log::Dispatch'} is undefined)";
    my $logger = Log::Dispatch->new(%$conf);
    Amon2::Util::add_method($c, 'log', sub { $logger });
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::LogDispatch - Log::Dispatch glue for Amon2

=head1 SYNOPSIS

    __PACKAGE__->load_plugin('LogDispatch');

    # in your config.pl
    'Log::Dispatch' => {
        outputs => [
            [Screen::Color', 
                min_level => 'debug',
                name      => 'debug',
                stderr    => 1,
                color     => {
                    debug => {
                        text => 'green',
                    }
                }
            ],
        ],
    },

    # in your controller
    $c->log->emerg('help me');

=head1 DESCRIPTION

This is a L<Log::Dispatch> glue for L<Amon2>. This module still maintained, but I don't use this module on production environment today.
I'm a user of L<Log::Minimal>.

B<I WILL SPLIT THIS PACKAGE FROM CORE DISTRIBUTION. IF YOU WANT TO USE IT, YOU SHOULD DEPEND TO THIS PACKAGE IMPLICITYLY>.

=head1 SEE ALSO

L<Amon2>, L<Log::Dispatch>

