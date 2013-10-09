use strict;
use warnings;
use Test::More;

<% block load_modules -> { %>
use <% $module %>;
use <% $module %>::Web;
use <% $module %>::Web::View;
use <% $module %>::Web::ViewFunctions;
<% } %>

pass "All modules can load.";

done_testing;
