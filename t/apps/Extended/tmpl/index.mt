? my $c = shift;
? extends 'base';
? block title => 'amon page';
? block content => sub {
hello, <?= c->req->mobile_agent->carrier_longname ?> world!
? };
