-- add a "see salary" attribute
alter table user add column seesalary enum('Y','N') not null default 'N';

alter table candidate add column salary varchar(100) default null;
