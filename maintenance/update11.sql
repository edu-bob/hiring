drop table if exists opening_action;

create table opening_action (
       id int unsigned not null auto_increment,
       opening_id int unsigned not null,
       action_id int unsigned not null,
       primary key(id),
       foreign key (opening_id) references opening(id),
       foreign key (action_id) references action(id)
);
