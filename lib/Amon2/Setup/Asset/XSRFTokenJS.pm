package Amon2::Setup::Asset::XSRFTokenJS;
use strict;
use warnings;

sub tags {
    <<',,,';
    <script src="<: uri_for('/static/js/xsrf-token.js') :>"></script>
,,,
}

sub files {
    return {
  'js/xsrf-token.js' => '(function (document) {
    "use strict";

    document.addEventListener("DOMContentLoaded", function () {
        var xsrf_token = getXSRFToken();
        var forms = document.querySelectorAll("form");
        for (var i = 0; i < forms.length; i++) {
            var form = forms[i];
            var method = form.getAttribute("method");
            if (method === "get" || method === "GET") {
                continue;
            }

            var input = document.createElement("input");
            input.setAttribute("type",  "hidden");
            input.setAttribute("name",  "XSRF-TOKEN");
            input.setAttribute("value", xsrf_token);
            form.insertBefore(input, form.firstChild);
        }

        function getXSRFToken() {
            var cookies = document.cookie.split(/\\s*;\\s*/);
            for (var i=0,l=cookies.length; i<l; i++) {
                var matched = cookies[i].match(/^XSRF-TOKEN=(.*)$/);
                if (matched) {
                    return matched[1];
                }
            }
            return undefined;
        }
    });
})(document);
'
}
;
}

1;
