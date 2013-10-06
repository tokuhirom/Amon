package <% $package // $module ~ "::Web::View" %>;
use strict;
use warnings;
use utf8;
use Carp ();
use File::Spec ();

use Text::Xslate 1.6001;
use <% $view_functions_package // ($module ~ "::Web::ViewFunctions") %>;

# setup view class
sub make_instance {
    my ($class, $context) = @_;
    Carp::croak("Usage: <% $module %>::View->make_instance(\$context_class)") if @_!=2;

    my $view_conf = $context->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir($context->base_dir(), '<% $tmpl_path ? $tmpl_path : 'tmpl' %>') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'Kolon',
        'module'   => [
            'Text::Xslate::Bridge::Star',
            '<% $view_functions_package // ($module ~ "::Web::ViewFunctions") %>',
        ],
        'function' => {
        },
        ($context->debug_mode ? ( warn_handler => sub {
            Text::Xslate->print( # print method escape html automatically
                '[[', @_, ']]',
            );
        } ) : () ),
        %$view_conf
    });
    return $view;
}

1;
