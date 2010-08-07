package DeepNamespace;
use parent qw/Amon2/;
__PACKAGE__->config({
        "Tfall::Text::MicroTemplate::Extended" => {
            include_path => ['tmpl'],
        }
    }
);
1;
