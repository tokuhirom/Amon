package DeepNamespace;
use Amon2 -base;
__PACKAGE__->config({
        "Tfall::Text::MicroTemplate::Extended" => {
            include_path => ['tmpl'],
        }
    }
);
1;
