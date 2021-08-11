alter table user add column my_opening_id int unsigned default null;

ALTER TABLE user ADD FOREIGN KEY (my_opening_id) REFERENCES opening(id);
