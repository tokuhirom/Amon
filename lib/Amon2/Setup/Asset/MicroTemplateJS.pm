# This file is generated by ./author/assets.pl. Do not edit manually.
package Amon2::Setup::Asset::MicroTemplateJS;
use strict;
use warnings;

sub tags {
    <<',,,';
    <script src="<: uri_for('/static/js/micro_template.js') :>"></script>
,,,
}

sub files {
    return {
  'js/micro_template.js' => '// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
(function(){
    var cache = {};
    this.tmpl = function tmpl(str, data){
        // Figure out if we\'re getting a template, or if we need to
        // load the template - and be sure to cache the result.
        var fn = !/\\W/.test(str) ?
            cache[str] = cache[str] ||
            tmpl(document.getElementById(str).innerHTML) :

        // Generate a reusable function that will serve as a template
        // generator (and which will be cached).
        new Function("obj",
                     "var p=[];" +

                     // Introduce the data as local variables using with(){}
                     "with(obj){p.push(\'" +

                     // Convert the template into pure JavaScript
                     str
                     .replace(/[\\r\\t\\n]/g, " ")
                     .split("<%").join("\\t")
                     .replace(/(^|%>)[^\\t]*?(\\t|$)/g, function(){return arguments[0].split("\'").join("\\\\\'");})
                     .replace(/\\t==(.*?)%>/g,"\',$1,\'")
                     .replace(/\\t=(.*?)%>/g, "\',(($1)+\'\').replace(/&/g,\'&amp;\').replace(/</g,\'&lt;\').replace(/>/g,\'&gt;\').replace(/\\"/g,\'&quot;\').replace(/\\\'/g,\'&#39;\'),\'")
                     .split("\\t").join("\');")
                     .split("%>").join("p.push(\'")
                     + "\');}return p.join(\'\');");

        // Provide some basic currying to the user
        return data ? fn( data ) : fn;
    };
})();
'
}
;
}

1;
