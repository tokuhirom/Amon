create table user (
    user_id integer primary key,
    email varchar(255) not null unique,
    nick varchar(255) not null,
    password varchar(255) not null
);
create index email on user (email);

create table status (
    status_id integer primary key,
    user_id integer not null,
    body varchar(255) not null
);

