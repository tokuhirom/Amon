? extends 'base.mt';
? block title => 'amon page';
? block content => sub {
hello, <?= req->mobile_agent->carrier_longname ?> world!
? };
