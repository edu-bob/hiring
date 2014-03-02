drop table if exists opening_evaluation;
drop table if exists evaluation;

create table evaluation (
       id int unsigned not null auto_increment,
       title varchar(100),
       content text,
       primary key(id)
);

create table opening_evaluation (
       id int unsigned not null auto_increment,
       opening_id int unsigned not null,
       evaluation_id int unsigned not null,
       primary key(id),
       foreign key (opening_id) references opening(id),
       foreign key (evaluation_id) references evaluation(id)
);
