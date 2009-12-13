package SampleApp::Dispatcher;
use HTTPx::Dispatcher;
connect '' => {controller => 'Root', action => 'index'};
1;
