<% cascade "Minimum/t/00_compile.t" %>
<% override load_modules -> { %>
use <% $module %>;
use <% $module %>::Web;
use <% $module %>::Web::Dispatcher;
use <% $module %>::Web::C::Root;
use <% $module %>::Web::C::Account;
use <% $module %>::Web::ViewFunctions;
use <% $module %>::Web::View;
use <% $module %>::Admin;
use <% $module %>::Admin::Dispatcher;
use <% $module %>::Admin::C::Root;
use <% $module %>::Admin::ViewFunctions;
use <% $module %>::Admin::View;
<% } %>
