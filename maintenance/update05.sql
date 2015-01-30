alter table user add column changestatus enum('Y','N') not null default 'N';
alter table user add column validated enum('Y','N') not null default 'N';
alter table user add column passwordkey char(32) default null;

