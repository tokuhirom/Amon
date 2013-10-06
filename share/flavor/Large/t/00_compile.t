<% cascade "Minimum/t/00_compile.t" %>
<% override load_modules -> { %>
use <% $module %>;
use <% $module %>::PC;
use <% $module %>::PC::Dispatcher;
use <% $module %>::PC::C::Root;
use <% $module %>::PC::C::Account;
use <% $module %>::PC::ViewFunctions;
use <% $module %>::PC::View;
use <% $module %>::Admin;
use <% $module %>::Admin::Dispatcher;
use <% $module %>::Admin::C::Root;
use <% $module %>::Admin::ViewFunctions;
use <% $module %>::Admin::View;
<% } %>
