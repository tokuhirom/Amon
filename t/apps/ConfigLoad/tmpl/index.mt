? extends 'base.mt';
? block title => 'amon page';
? use Data::Dumper;
? block content => sub { Dumper(global_config) };

