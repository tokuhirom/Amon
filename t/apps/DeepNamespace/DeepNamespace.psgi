use DeepNamespace;
use DeepNamespace::Web::User;
DeepNamespace::Web::User->to_app(
    config => {
        "Tfall::Text::MicroTemplate::Extended" => {
            include_path => ['tmpl'],
        }
    }
);
