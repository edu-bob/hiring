-- MySQL dump 10.9
--
-- Host: localhost    Database: hiring
-- ------------------------------------------------------
-- Server version	4.1.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `action`
--

DROP TABLE IF EXISTS `action`;
CREATE TABLE `action` (
  `id` int unsigned NOT NULL auto_increment,
  `action` varchar(32) default NULL,
  `precedence` mediumint(9) default NULL,
  `category_id` int unsigned default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `action_category`
--

DROP TABLE IF EXISTS `action_category`;
CREATE TABLE `action_category` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `name` varchar(32) default NULL,
  `precedence` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `audit`
--

DROP TABLE IF EXISTS `audit`;
CREATE TABLE `audit` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `type` enum('ADD','CHANGE','REMOVE') NOT NULL default 'CHANGE',
  `dbtable` varchar(32) NOT NULL default '',
  `dbcolumn` varchar(32) NOT NULL default '',
  `oldvalue` varchar(100) default NULL,
  `newvalue` varchar(100) default NULL,
  `row` mediumint(9) default NULL,
  `user_id` int unsigned default NULL,
  `join_table` varchar(32) default NULL,
  `join_id` int unsigned default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `candidate`
--

DROP TABLE IF EXISTS `candidate`;
CREATE TABLE `candidate` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `name` varchar(100) NOT NULL default '',
  `homephone` varchar(24) default NULL,
  `workphone` varchar(24) default NULL,
  `cellphone` varchar(24) default NULL,
  `homeemail` varchar(100) default NULL,
  `workemail` varchar(100) default NULL,
  `action_id` int unsigned default NULL,
  `owner_id` int unsigned default NULL,
  `hide` smallint(6) default '0',
  `opening_id` int unsigned default NULL,
  `modtime` datetime default '1970-01-01 00:00:00',
  `referrer` varchar(40) default NULL,
  `referrer_type` enum('INTERNAL','RECRUITER','WEBSITE','ADVERTISEMENT','BOARDS','OTHER') default NULL,
  `recruiter_ref` varchar(32) default NULL,
  `status` enum('NEW','ACTIVE','REJECTED','HIRED','CLOSED','TEST','SHELVED') NOT NULL default 'NEW',
  `recruiter_id` int unsigned default NULL,
  `external` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `candidate_keyword`
--

DROP TABLE IF EXISTS `candidate_keyword`;
CREATE TABLE `candidate_keyword` (
  `candidate_id` int unsigned NOT NULL default '0',
  `keyword_id` int unsigned NOT NULL default '0'
) ENGINE=Innodb DEFAULT CHARSET=utf8;


--
-- Table structure for table `category_count`
--

DROP TABLE IF EXISTS `category_count`;
CREATE TABLE `category_count` (
  `thetime` datetime default NULL,
  `count` int(10) unsigned default NULL,
  `category_id` int unsigned default NULL
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `cc`
--

DROP TABLE IF EXISTS `cc`;
CREATE TABLE `cc` (
  `id` int unsigned NOT NULL auto_increment,
  `candidate_id` int unsigned default NULL,
  `user_id` int unsigned default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
  `id` int unsigned NOT NULL auto_increment,
  `comment` text NOT NULL,
  `candidate_id` int unsigned NOT NULL default '0',
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `user_id` int unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `cron`
--

DROP TABLE IF EXISTS `cron`;
CREATE TABLE `cron` (
  `id` int unsigned NOT NULL auto_increment,
  `type` enum('EVERY','DOW','DOM') default NULL,
  `dow` int(11) default NULL,
  `dom` int(11) default NULL,
  `time` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `department`
--

DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `id` int unsigned NOT NULL auto_increment,
  `name` varchar(32) NOT NULL default '',
  `abbrev` varchar(8) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `department_admin`
--

DROP TABLE IF EXISTS `department_admin`;
CREATE TABLE `department_admin` (
  `id` int unsigned NOT NULL auto_increment,
  `department_id` int unsigned NOT NULL default '0',
  `sendmail` enum('Y','N') default 'Y',
  `user_id` int unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `document`
--

DROP TABLE IF EXISTS `document`;
CREATE TABLE `document` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `candidate_id` int unsigned NOT NULL default '0',
  `contents` varchar(32) default NULL,
  `filename` varchar(80) NOT NULL default '',
  `data` mediumblob,
  `size` int(11) default NULL,
  `temporary` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `candidate_id` (`candidate_id`),
  KEY `temporary` (`temporary`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `frontlink`
--

DROP TABLE IF EXISTS `frontlink`;
CREATE TABLE `frontlink` (
  `id` int unsigned NOT NULL auto_increment,
  `description` varchar(100) NOT NULL default '',
  `url` varchar(100) NOT NULL default '',
  `side` enum('RIGHT','LEFT') default 'LEFT',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `interview`
--

DROP TABLE IF EXISTS `interview`;
CREATE TABLE `interview` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `candidate_id` int unsigned default NULL,
  `date` date default NULL,
  `purpose` varchar(80) default NULL,
  `status` enum('PENDING','COMPLETED','CANCELLED') default NULL,
  `note_interviewer` text,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `interview_person`
--

DROP TABLE IF EXISTS `interview_person`;
CREATE TABLE `interview_person` (
  `id` int unsigned NOT NULL auto_increment,
  `interview_slot_id` int unsigned default NULL,
  `user_id` int unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `interview_slot`
--

DROP TABLE IF EXISTS `interview_slot`;
CREATE TABLE `interview_slot` (
  `id` int unsigned NOT NULL auto_increment,
  `interview_id` int unsigned default NULL,
  `time` int unsigned default NULL,
  `duration` int unsigned default NULL,
  `location` varchar(40) default NULL,
  `topic` text,
  `hide` int unsigned default NULL,
  `type` enum('INTERVIEW','BREAK','BREAKFAST','LUNCH','DINNER','PHONE','OTHER') default 'INTERVIEW',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `keyword`
--

DROP TABLE IF EXISTS `keyword`;
CREATE TABLE `keyword` (
  `id` int unsigned NOT NULL auto_increment,
  `keyword` varchar(32) NOT NULL default '',
  `description` varchar(100) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `opening`
--

DROP TABLE IF EXISTS `opening`;
CREATE TABLE `opening` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `number` varchar(10) NOT NULL default '',
  `description` varchar(80) NOT NULL default '',
  `status` enum('PENDING','OPEN','FILLED') NOT NULL default 'PENDING',
  `department_id` int unsigned default NULL,
  `url` varchar(255) default NULL,
  `priority` varchar(6) default NULL,
  `duedate` date default NULL,
  `owner_id` int unsigned default NULL,
  `short_key` varchar(32) default NULL,
  PRIMARY KEY  (`id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `param`
--

DROP TABLE IF EXISTS `param`;
CREATE TABLE `param` (
  `id` int unsigned NOT NULL auto_increment,
  `name` varchar(64) NOT NULL default '',
  `value` varchar(64) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `rating`
--

DROP TABLE IF EXISTS `rating`;
CREATE TABLE `rating` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `rating` decimal(5,2) NOT NULL default '0.00',
  `comment` varchar(100) default NULL,
  `candidate_id` int unsigned default NULL,
  `user_id` int unsigned default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `recruiter`
--

DROP TABLE IF EXISTS `recruiter`;
CREATE TABLE `recruiter` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `name` varchar(64) NOT NULL default '',
  `agency` varchar(64) default NULL,
  `email` varchar(64) default NULL,
  `address1` varchar(64) default NULL,
  `address2` varchar(64) default NULL,
  `city` varchar(32) default NULL,
  `state` varchar(16) default NULL,
  `contract` int unsigned default NULL,
  `notes` varchar(250) default NULL,
  `active` enum('Y','N') NOT NULL default 'Y',
  `zipcode` varchar(16) default NULL,
  `phone` varchar(24) default NULL,
  `cell` varchar(24) default NULL,
  `fax` varchar(24) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `suggestion`
--

DROP TABLE IF EXISTS `suggestion`;
CREATE TABLE `suggestion` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime NOT NULL default '0000-00-00 00:00:00',
  `submitter_id` int unsigned NOT NULL default '0',
  `content` text NOT NULL,
  `status` enum('OPEN','DEVELOPMENT','COMPLETED','REJECTED') NOT NULL default 'OPEN',
  `priority` enum('P1','P2','P3','P4') NOT NULL default 'P1',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `temp_dir`
--

DROP TABLE IF EXISTS `temp_dir`;
CREATE TABLE `temp_dir` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `tempdir`
--

DROP TABLE IF EXISTS `tempdir`;
CREATE TABLE `tempdir` (
  `id` int unsigned NOT NULL auto_increment,
  `creation` datetime default NULL,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `template`
--

DROP TABLE IF EXISTS `template`;
CREATE TABLE `template` (
  `id` int unsigned NOT NULL auto_increment,
  `table_name` varchar(32) default NULL,
  `column_name` varchar(32) default NULL,
  `template` text,
  `name` varchar(64) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int unsigned NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  `title` varchar(40) NOT NULL default '',
  `email` varchar(40) NOT NULL default '',
  `admin` enum('N','Y') default 'N',
  `password` varchar(32) default NULL,
  `sendmail` enum('Y','N') default NULL,
  `remind` enum('Y','N') default 'Y',
  `active` enum('Y','N') NOT NULL default 'Y',
  PRIMARY KEY  (`id`)
) ENGINE=Innodb DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

