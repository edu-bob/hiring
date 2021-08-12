#!/usr/bin/perl -w
use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img *p -nosticky);

BEGIN {push @INC, "..";}

require "globals.pl";

use Database;
use Utility;

my $html = 0;
if ( exists $ENV{'REQUEST_URI'} ) {
    $html = 1;
}
Utility::setHTMLErrors($html);

if ( -f "candidates.cgi" ) {
    chdir("test");
} elsif ( ! -f "../candidates.cgi" ) {
    print "This must be run from the document root for the candidate tracker or from 'test'\n";
    exit(1);
}

print header if $html;
print start_html if $html;

print h1("Candidate tracker - mysql test"),hr if $html;
print start_p if $html;
print "Testing the database setup.\n\n";
print end_p if $html;

if ( ConnectToDatabase(1) ) {
    print start_p if $html;
    print "Congratulations!  The database appears to be set up correctly!.\n";
    print end_p if $html;
    print start_p if $html;
    print "Next step is to edit the baseline content put into the database.\n";
    print end_p if $html;
    if ( $html ) {
	print p("Use each of these links in order:",
		ol(
		   li(a({-href=>"../manage.cgi?table=param", -target=>"_blank"}, "Edit application parameters")),
		   li(a({-href=>"../manage.cgi?table=department", -target=>"_blank"}, "Edit corporate departments")),
		   li(a({-href=>"../manage.cgi?table=action_category", -target=>"_blank"}, "Edit workflow action categories")),
		   li(a({-href=>"../manage.cgi?table=action", -target=>"_blank"}, "Edit workflow actions")),
		   ),
		a({-href=>"../"}, "Finally, go to the Tracker home page"),
		);
    } else {
	print "You must use the application to do this.  See the INSTALL file for details.\n";
    }
} else {
    print start_p if $html;
    print "\nPlease fix the existence or access problems with the database before proceeding.\n";
    print end_p if $html;
}

if ( $html ) {
    my @tables = GetTableNames();
    print h2("Tables"), start_ul;
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
}


print end_html if $html;
