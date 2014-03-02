##
## The host where the mysql database server runs
##
$::DB_HOST = "localhost";
##
## The name of the database
##
$::DB_NAME = "hiring";
##
## The name and password of the authorized user for the database
##
$::DB_USER = "hiring";
$::DB_PASS = "modeln";
##
## The connect string (don't change this)
##
$::DB_SOURCE = "DBI:mysql:$::DB_NAME:$::DB_HOST";
