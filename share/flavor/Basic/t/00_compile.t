<% cascade "Minimum/t/00_compile.t" %>
<% after load_modules -> { %>
use <% $module %>::DB::Schema;
use <% $module %>::Web::Dispatcher;
<% } %>
