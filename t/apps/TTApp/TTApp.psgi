use TTApp;
use TTApp::Web;
TTApp::Web->to_app(
    config => {
        'Tfall::TT' => {
            INCLUDE_PATH => ['tmpl/'],
        },
    },
);
