alter table user add column opening_id int unsigned default null;

ALTER TABLE user ADD FOREIGN KEY (opening_id) REFERENCES opening(id);
