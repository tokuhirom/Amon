package Hello::Web::Dispatcher;
use Amon::Web::Dispatcher::HTTPxDispatcher;

connect '/'              => { controller => 'Root', action => 'index' };
connect '/signup'        => { controller => 'Root', action => 'signup' };
connect '/signup_thanks' => { controller => 'Root', action => 'signup_thanks' };
connect '/login'         => { controller => 'Root', action => 'login' };
connect '/logout'        => { controller => 'Root', action => 'logout' };
connect '/post'          => { controller => 'Root', action => 'post' };

1;
