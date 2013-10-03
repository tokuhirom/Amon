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
requires 'Router::Simple', '0.14';
requires 'Router::Simple::Sinatraish', '0.02';
requires 'Scalar::Util';
requires 'Text::Xslate', '1.6001';
requires 'Try::Tiny', '0.06';
requires 'URI', '1.54';
requires 'URI::Escape';
requires 'URI::QueryParam';
requires 'File::Copy::Recursive'; # setup script

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
};
