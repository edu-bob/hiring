DROP TABLE IF EXISTS `opening_cc`;
CREATE TABLE `opening_cc` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `opening_id` int unsigned not NULL,
  `user_id` int unsigned not NULL,
  FOREIGN KEY (opening_id) REFERENCES opening(id),
  FOREIGN KEY (user_id) REFERENCES user(id),
  PRIMARY KEY  (`id`)
) ENGINE=innodb DEFAULT CHARSET=utf8;
