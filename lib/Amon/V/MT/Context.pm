package Amon::V::MT::Context;
use strict;
use warnings;
use base 'Exporter';
use Text::MicroTemplate 'encoded_string';
use Amon::Web::Declare;

our @EXPORT = (qw/block extends encoded_string/, @Amon::Web::Declare::EXPORT);

sub import {
    strict->import;
    warnings->import;

    __PACKAGE__->export_to_level(1);
}

# following code is taken from Text::MicroTemplate::Extended by typester++.
sub extends {
    $Amon::V::MT::render_context->{extends} = $_[0];
}

sub block {
    my ($name, $code) = @_;

    no strict 'refs';

    my $block;
    if (defined $code) {
        $block = $Amon::V::MT::render_context->{blocks}{$name} ||= {
            context_ref => ${"@{[ $Amon::V::MT::render_context->{c}->context_class ]}::_MTREF"},
            code        => ref($code) eq 'CODE' ? $code : sub { return $code },
        };
    }
    else {
        $block = $Amon::V::MT::render_context->{blocks}{$name}
            or die qq[block "$name" does not define];
    }

    if (!$Amon::V::MT::render_context->{extends}) { # if base template.
        my $current_ref = ${"@{[ $Amon::V::MT::render_context->{c}->context_class ]}::_MTREF"};
        my $block_ref   = $block->{context_ref};

        my $rendered = $$current_ref || '';
        $$block_ref = '';

        my $result = $block->{code}->() || $$block_ref || '';

        $$current_ref = $rendered . $result;
    }
}

1;
