package Amon;
use strict;
use warnings;
use Amon::Util;
use 5.008001;
use File::Spec;

our $VERSION = 0.01;
{
    our $_context;
    sub context { $_context }
    sub set_context { $_context = $_[1] }
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller(0);

    strict->import;
    warnings->import;


    no strict 'refs';
    if (my $config_class = $args{config_class}) {
        Amon::Util::load_class($config_class);
        *{"${caller}::config_class"}       = sub { $config_class };
        *{"${caller}::config"} = sub {
            my $self = $_[0];
            my $cc = $self->config_class;
            Amon::Util::load_class($cc);
            my $conf = $cc->instance;
            no strict 'refs';
            no warnings 'redefine';
            *{"@{[ ref $self ]}::config"} = sub {
                $conf
            };
            return $conf;
        };
    } else {
        *{"${caller}::config"} = sub { +{ } };
    }
    for my $meth (qw/new base_dir model web_base request/) {
        *{"${caller}::${meth}"} = *{"${class}::${meth}"};
    }
}

sub new {
    my ($class, %args) = @_;
    bless {%args}, $class;
}

# OVERWRITABLE
sub base_dir {
    my $class = shift;
    $class = ref $class if ref $class;
    no strict 'refs';
    ${"${class}::_base_dir"} ||= do {
        my $path = $class;
        $path =~ s!::!/!g;
        if (my $libpath = $INC{"$path.pm"}) {
            $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
            File::Spec->rel2abs($libpath || './');
        } else {
            File::Spec->rel2abs('./');
        }
    };
}

sub model($) {
    my ($self, $name) = @_;
    my $klass = "@{[ ref $self ]}::M::$name";
    $self->{_components}->{$klass} ||= do {
        Amon::Util::load_class($klass);
        my $config = $self->config()->{"M::$name"};
        $klass->new($config ? $config : ());
    };
}

# web related accessors
sub web_base { $_[0]->{web_base} }
sub request  { $_[0]->{request}  }

1;
__END__

=head1 NAME

Amon - lightweight web application framework

=head1 SYNOPSIS

    $ amon-setup.pl MyApp

=head1 Point

    Fast
    Easy to use

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

