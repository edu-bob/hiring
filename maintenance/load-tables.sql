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
-- Dumping data for table `param`
--


/*!40000 ALTER TABLE `param` DISABLE KEYS */;
INSERT INTO `param` (`id`, `name`, `value`) VALUES 
  (4,'hostname','yourhost.yourdomain.com'),
  (2,'title','Your Company Candidate Tracker'),
  (3,'refresh','4'),
  (5,'e-mail-from','tracker');
/*!40000 ALTER TABLE `param` ENABLE KEYS */;

--
-- Dumping data for table `action`
--


/*!40000 ALTER TABLE `action` DISABLE KEYS */;
INSERT INTO `action` (`id`, `action`, `precedence`, `category_id`) VALUES
  (1,'complete technical phone screen',20,5),
  (2,'schedule first round interview',30,6),
  (3,'complete first round interview',35,6),
  (4,'schedule next round interview',50,6),
  (5,'complete next round interview',55,6),
  (6,'functional resume review',10,5),
  (7,'hold - in screening',13,5),
  (8,'create offer',100,7),
  (9,'sign offer letter',500,7),
  (10,'none',1,NULL),
  (12,'qualify for screening',5,4),
  (13,'send reject note',200,NULL),
  (14,'check references',75,6),
  (15,'refer to another department',65,0),
  (16,'start work',1000,NULL),
  (17,'evaluate screening content',25,5),
  (18,'wait for contact information',11,5),
  (19,'schedule technical phone screen',15,5),
  (20,'schedule on-site screening',22,5),
  (21,'complete on-site screening',23,5),
  (22,'please advise',14,0),
  (23,'wait for code test answers',11,5),
  (24,'evaluate code test answers',12,5),
  (25,'hold - in interviewing',40,6);
/*!40000 ALTER TABLE `action` ENABLE KEYS */;

--
-- Dumping data for table `action_category`
--


/*!40000 ALTER TABLE `action_category` DISABLE KEYS */;
INSERT INTO `action_category` (`id`, `creation`, `name`, `precedence`) VALUES
  (5,'2005-08-26 14:21:03','Screening',20),
  (4,'2005-08-26 14:20:48','Sourcing',10),
  (6,'2005-08-26 14:21:20','Interviewing',30),
  (7,'2005-08-26 14:21:32','Offering',40);
/*!40000 ALTER TABLE `action_category` ENABLE KEYS */;

--
-- Dumping data for table `department`
--


/*!40000 ALTER TABLE `department` DISABLE KEYS */;
INSERT INTO `department` (`id`, `name`, `abbrev`) VALUES
  (1,'Engineering','ENG'),
  (2,'Customer Success','CS'),
  (3,'Products','PROD'),
  (4,'Administration','ADMIN'),
  (5,'Marketing','MKTG');
/*!40000 ALTER TABLE `department` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO user ( id, name, title, email, admin ) VALUES
  (1, "Set Up User", "Set Up User", "root@localhost", 'Y')
