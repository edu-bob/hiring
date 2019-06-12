#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;

use Layout;
use Database;
require "globals.pl";

use CGI qw(:standard *ul *pre *p);
use CGI::Carp qw(fatalsToBrowser);

# Use the DBI module
use DBI;

my ($server, $sock, $host);

my $file = param("sql");
my $version = param("version");
my $self_url = self_url();

ConnectToDatabase();

print header;

print doHeading({-title=>"Update Tables"}), "\n";

print p(b("File: $file")), "\n";
my $success = 0;
if ( defined param("version") ) {
	if ( $version > 0 ) {
		my $dbversion = GetDBVersion();
		if ( $version == $dbversion ) {
			print p(b("Required version: $version [MATCHES]")), "\n";
			$success = 1;
		} else {
			print p(b("Required version: $version [MISMATCH, database is $dbversion]")), "\n";
			print p(b("Giving up - no database update performed.")), "\n";
			$success = 0;
		}
	} else {
		print p(b("Required version == 0, proceeding.")), "\n";
		$success = 1;
	}
} else {
	print p(b("No expected version number given, giving up.")), "\n";
	$success = 0;
}

if ( $success ) {
    my $op;
    $op = param("op") or $op = 1;
    if ( $op == 1 ) {
		do_confirm();
    } else {
		do_sql($file);
    }
}

print Footer({-url=>"$self_url"});
print end_html();
exit(0);

##################################################################
sub do_confirm
{
    print p(b("WARNING: This could damage your database!!!")), "\n";
    print start_form, "\n";
    print hidden({-name=>"op", -default=>"2"});
    print hidden({-name=>"sql", -default=>"$file"});
    print hidden({-name=>"version", -default=>"$version"});
    print submit, "\n";
    print end_form, "\n";
}

##################################################################
## do_sql - execute the SQL commands on the database
##################################################################
sub do_sql
{
    my $file = shift;

  BODY: {

      if ( ! $file ) {
	  print p(b("Error: No SQL file specified"));
	  last BODY;
      }

##
## Try connecting to the database
##

      if ( !ConnectToDatabase() ) {
	  print p("Connect to database failed");
	  print p($DBI::errstr);
	  last BODY;
      }

##
## Read and execute the commands in the schema creation script
##

      open SQL, "$file" or do {
	  print p(b(i("ERROR: $file: $!")));
	  last BODY;
      };

      my $line;
      my $sql = "";
      my $out;
      my $in_comment = 0;
      while ( defined ($line = <SQL>) ) {
#    chomp $line;
	  if ( $line =~ /^$/ ) {
	      if ( $in_comment ) {
		  print end_p;
		  $in_comment = 0;
	      }
	      if ( length $sql > 0 ) {
		  print pre("$sql");
		  SQLSend($sql);
		  my $rows = SQLAffectedRows();
		  print p("$rows rows affected");
		  $sql = "";
	      }
	  } elsif ( $line =~ /^\#/ ) {
	      if ( !$in_comment ) {
		  $in_comment = 1;
		  print start_p;
	      }
	      print b("$line"), br();
	  } else {
	      $sql = $sql . " " . $line;
	  }
      }
      close SQL;
      if ( length $sql > 0 ) {
	  print pre("$sql");
	  SQLSend($sql);
	  my $rows = SQLAffectedRows();
	  print p("$rows rows affected");
	  $sql = "";
      }

      my @tables = GetTableNames();
      print h2("Tables"), start_ul;
      if ( scalar @tables == 0 ) {
	  print li("No tables in this database");
      } else {
	  foreach ( @tables ) {
	      print li("$_"), "\n";
	  }
      }
      print end_ul;

  }; #BODY

}

