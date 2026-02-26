#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.008001;
use lib 'lib';
use LWP::UserAgent;
use autodie;
use Data::Dumper;
use File::Basename;
use File::Temp qw/tmpnam tempdir/;
use Text::Xslate;

my $xslate = Text::Xslate->new(
    syntax    => 'TTerse',
    module    => ['Data::Dumper'],
    type      => 'text',
    tag_start => '<%',
    tag_end   => '%>',
);

&main;exit;

sub main {
    local $Data::Dumper::Terse = 1;

    run_xsrf_token_js();
}

sub run_xsrf_token_js {
    my $content = <<'...';
(function (document) {
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
            var cookies = document.cookie.split(/\s*;\s*/);
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
...

    open my $fh, '>:utf8', 'lib/Amon2/Setup/Asset/XSRFTokenJS.pm';
    print {$fh} $xslate->render_string(<<'...', +{ file => $0, data => Dumper({ 'js/xsrf-token.js' => $content})});
package Amon2::Setup::Asset::XSRFTokenJS;
use strict;
use warnings;

sub tags {
    <<',,,';
    <script src="<: uri_for('/static/js/xsrf-token.js') :>"></script>
,,,
}

sub files {
    return <% data %>;
}

1;
...
    close $fh;
}
