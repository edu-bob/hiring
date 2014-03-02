#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr);
use CGI::Carp;
       
# Use the DBI module
use DBI;
#CGI::use_named_parameters(1);

my ($server, $sock, $host);

my $db_host = "localhost";         # where is the database?
my $db_port = 3306;                # which port to use
my $db_name = "hiring";              # name of the MySQL database
my $db_user = "hiring";              # user to attach to the MySQL database

my $db_source = "DBI:mysql:hiring";

$server = param('server') or $server = $db_host;

print header, start_html({'title'=>"Information on $server", -style=>{-src=>"style.css"}});

print h1("$server");

BODY: {

my @available_drivers = DBI->available_drivers;
print h2("Available Drivers (available_drivers)"), "\n";
my $have_mysql = 0;
print start_ul;
foreach ( @available_drivers ) {
    if ( $_ eq "mysql" ) {
	$have_mysql = 1;
	print li(font({-color=>"#aa00aa"},$_));
    } else {
	print li($_);
    }
    print "\n";
}
print end_ul;

if ( !$have_mysql ) {
    print p(b("ERROR: no mysql DBD installed for DBI"));
    last BODY;
}
##
## data sources
##

my @data_sources = DBI->data_sources('mysql');
print h2("mysql Data Sources (data_sources)");
print start_ul;
foreach (@data_sources) {
    if ( $_ eq $db_source ) {
	print li(font({-color=>"#aa00aa"},$_));
    } else {
	print li("$_");
    }
    print "\n";
}
print end_ul;

##
## Databases from the driver
##

# Prepare the MySQL DBD driver
my $driver = DBI->install_driver('mysql');

my @databases = $driver->func($server, '_ListDBs');

# If @databases is undefined, we assume that means that the host does not have
# a running MySQL server. However, there could be other reasons
# for the failure. You can find a complete error message by
# checking $DBI::errmsg.
if (not @databases) {
    print p("$server does not appear to have a running MySQL server."), "\n";
    print p($DBI::errstr);
    last BODY;
}

print h2("Databases:");
print start_ul();
foreach (@databases) {
    print li("$_");
}
print end_ul();


}; #BODY

print end_html();

exit(0);
