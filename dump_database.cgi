#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr *td);
use CGI::Carp;

use Database;
use Layout;
use Param;

require "globals.pl";

doMysqldump();

exit 0;



sub doMysqldump
{
    ConnectToDatabase();
    my $mysqldump = Param::getValueByName("mysqldump");
    if ( !defined $mysqldump ) {
	$mysqldump = "mysqldump";
    }

    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
        $wday, $yday, $isdst) = localtime(time);
    my $tstamp = sprintf("%04d%02d%02d%02d%02d%02d",
                   1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds);


    my @cmd = ( $mysqldump,
		"--opt", 
		"--host=$::DB_HOST",
		"--user=$::DB_USER",
		"--password=$::DB_PASS",
		$::DB_NAME);
    print header({
#	-type=>"application/x-download",
	-type=>"application/octet-stream",
	-attachment=>"tracker_backup_$tstamp.sql"},
		 );
    system(@cmd);
}
