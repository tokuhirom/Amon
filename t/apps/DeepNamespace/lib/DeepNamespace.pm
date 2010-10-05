package DeepNamespace;
use parent qw/Amon2/;
sub load_config {
    +{
        "Text::MicroTemplate::Extended" => {
            include_path => ['tmpl'],
        }
    }
}

1;
