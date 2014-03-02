#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr);
use CGI::Carp qw(fatalsToBrowser);;

# Use the DBI module
use DBI;

use Layout;
use Database;

require "globals.pl";

#CGI::use_named_parameters(1);

my ($server, $sock, $host);

my $db_host = "localhost";         # where is the database?
my $db_source = "DBI:mysql:hiring";

my $self_url = self_url();

$server = param('server') or $server = $db_host;

print header, start_html({'title'=>"Database Tables", -style=>{-src=>"style.css"}});

print h1("$server");

 BODY: {


##
## Try connecting to the database
##

     ConnectToDatabase();

##
## List the names of the tables
##


     my @tables = GetTableNames();
     print h2("Tables in $db_source"), start_ul;
     if ( scalar @tables == 0 ) {
         print li("No tables in this database");
     } else {
         foreach ( @tables ) {
             print li(a({-href=>"#$_"}, "$_")), "\n";
         }
     }
     print end_ul;

##
## Print out the structure of the tables
##

     print h2("Schema"), "\n";
     foreach ( @tables ) {
         print h3(a({-name=>"$_"}, "$_")), "\n";
         dumpTableSchema({-table=>"$_"});
     }

 }; #BODY

print Footer({-url=>"$self_url"});

print end_html();

exit(0);

