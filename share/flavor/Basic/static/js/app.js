if (typeof(window.console) == "undefined") { console = {}; console.log = console.warn = console.error = function(a) {}; }

var <%= $app %> = angular.module('<% $app %>', ['ngResource']);
<% $app %>.config(function($httpProvider) {
    var csrf_token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = csrf_token;
});
/*
<% $app %>.factory('EntryResource', function ($resource, $log) {
    return $resource('/api/entry/:id');
});
*/

<% $app %>.controller('RootCtrl', function ($scope, $resource, $log) {
});

