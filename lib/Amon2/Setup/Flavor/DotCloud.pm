use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::DotCloud;

1;
__DATA__

@@ dotcloud.yml
www:
  perl

@@ #status.html
<!doctype html> 
<html> 
    <head> 
        <meta charset=utf-8 /> 
        <style type="text/css"> 
            body {
                text-align: center;
                font-family: 'Menlo', 'Monaco', Courier, monospace;
                background-color: whitesmoke;
                padding-top: 10%;
            }
            .number {
                font-size: 800%;
                font-weight: bold;
                margin-bottom: 40px;
            }
            .message {
                font-size: 400%;
            }
        </style> 
    </head> 
    <body> 
        <div class="number"><:= $status :></div> 
        <div class="message"><:= $message :></div> 
    </body> 
</html> 

@@ static/404.html
: include "#status.html" { status => 404, message => 'Not Found' };

@@ static/500.html
: include "#status.html" { status => 500, message => 'Internal Server Error' };

@@ static/502.html
: include "#status.html" { status => 502, message => 'Bad Gateway' }

@@ static/503.html
: include "#status.html" { status => 503, message => 'Service Unavailable' };

@@ static/504.html
: include "#status.html" { status => 504, message => 'Gateway Timeout' }

__END__

=head1 NAME

Amon2::Setup::Flavor::DotCloud - dotcloud

=head1 SYNOPSIS

This is a flavor for dotcloud. This flavor creates setting files for dotcloud.
