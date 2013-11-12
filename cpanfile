requires 'perl', '5.008001';

requires 'Encode';
requires 'Exporter';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'Hash::MultiValue';
requires 'HTML::FillInForm::Lite';
requires 'HTTP::Headers';
requires 'JSON', '2';
requires 'MRO::Compat';
requires 'parent', '0.223';
requires 'Plack', '0.9982';
requires 'Plack::Request';
requires 'Plack::Response';
requires 'Plack::Session';
requires 'Plack::Util';
requires 'Pod::Usage';
requires 'Router::Boom', '0.07';
requires 'Scalar::Util';
requires 'Text::Xslate', '2.0010';
requires 'Try::Tiny', '0.06';
requires 'URI', '1.54';
requires 'URI::Escape';
requires 'URI::QueryParam';
requires 'File::Copy::Recursive'; # setup script
requires 'File::ShareDir';
requires 'Module::CPANfile', '0.9020';
requires 'HTTP::Session2';

recommends 'Teng', 0.18;

# HTTPSession
suggests 'HTTP::Session';

# Websocket support
suggests 'AnyEvent::Handle';
suggests 'Protocol::WebSocket', '0.00906';
suggests 'Protocol::WebSocket::Frame';
suggests 'Protocol::WebSocket::Handshake::Server';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires', '0.06';

    suggests 'File::pushd';
    suggests 'AnyEvent';
    suggests 'AnyEvent::Socket';
    suggests 'App::Prove';
    suggests 'HTTP::Request::Common';
    suggests 'HTTP::Session::Store::OnMemory';
    suggests 'Plack::Builder';
    suggests 'Plack::Middleware::Lint';
    suggests 'Plack::Middleware::Session';
    suggests 'Plack::Test';
    suggests 'Test::TCP';
    suggests 'Tiffany';
    suggests 'Twiggy::Server';
    suggests 'Test::WWW::Mechanize';
    suggests 'App::cpanminus';
    suggests 'File::Which';
    suggests 'DBD::SQLite';
    suggests 'Furl';
    suggests 'Module::Functions';
    suggests 'HTTP::MobileAgent';
    suggests 'Text::MicroTemplate::Extended';
    suggests 'Module::Find';
    suggests 'Amon2::Plugin::LogDispatch';
    suggests 'HTML::StickyQuery';
    suggests 'Amon2::Plugin::Web::MobileAgent';
    suggests 'Test::WWW::Mechanize::PSGI';
    suggests 'Amon2::Plugin::Web::HTTPSession';
    suggests 'Plack::Middleware::ReverseProxy';
    suggests 'Starlet';
    suggests 'Router::Simple::Sinatraish';
    suggests 'Amon2::DBI';
};

