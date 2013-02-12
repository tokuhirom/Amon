package Amon2::LocalContext;
use strict;
use warnings;
use utf8;

sub import {
    my $class = shift;
    my $pkg = caller(0);

    # use eval to generate fastest code.

    ## no critic.
    eval sprintf(q{
        package %s;

        sub context     { $%s::CONTEXT }

        sub set_context { $%s::CONTEXT = $_[1] }

        sub context_guard {
            Amon2::ContextGuard->new($_[0], \$%s::CONTEXT);
        }
    }, $pkg, $pkg, $pkg, $pkg);
    die $@ if $@;
}

1;
__END__

=head1 NAME

Amon2::LocalContext - (EXPERIMENTAL)Make context as project local

=head1 SYNOPSIS

    package MyApp;
    use parent qw(Amon2::Web);
    use Amon2::LocalContext; # 'import' method makes something

=head1 DESCRIPTION

Normally, Amon2's context is stored in global variable.

This module makes the context to project local.

It means, normally context class using Amon2 use C<$Amon2::CONTEXT> in each project, but context class using Amon2::LocalContext use C<$MyApp::CONTEXT>.

=head1 NOTES ABOUT create_request

Older Amon2's setup script defines create_request method as following, and it uses C<< Amon2->context >> to get encoding:

    sub create_request {
        my ($class, $env) = @_;
        Amon2::Web::Request->new($env);
    }

If you want to use Amon2::LocalContext, you need to pass class name of context class, as following:

    sub create_request {
        my ($class, $env) = @_;
        Amon2::Web::Request->new($env, $class);
    }

=head1 METHODS

This module inserts 3 methods to your context class.

=over 4

=item MyApp->context()

Shorthand for $MyApp::CONTEXT

=item MyApp->set_context($context)

It's same as:

    $MyApp::CONTEXT = $context

=item my $guard = MyApp->context_guard()

Create new context guard class.

It's same as:

    Amon2::ContextGuard->new(shift, \$MyApp::CONTEXT);

=back

=head1 WARNINGS

Some plugin and your code are depended on C<<Amon2->context>>.

=head1 FUTURE PLAN

This behavior will be default at Amon3.
(It mean I don't introduce this incompatible behavior to Amon2)

