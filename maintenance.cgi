#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);
use CGI::Carp qw(fatalsToBrowser);;

use Application;
use Layout;
use Database;

require "globals.pl";
require "tables.pl";

use ParamTable;

Application::Init();

print header;

if ( defined param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "delete" and do {
          last SWITCH;
      };
  };
} else {
    firstPage();
}
exit(0);

sub firstPage
{
	ConnectToDatabase();
	my $version = getValueMatch({
		-table=>\%::ParamTable,
		-column=>"name",
		-equals=>"version",
		-return=>"value",
		});
	print doHeading({-title=>"Database Maintenance"} ), "\n";
	
  BODY: {
	  
	  ConnectToDatabase();
	  
	  print start_table({ -border=>"3", -cellspacing=>"8", -width=>"100%"}), "\n";
	  print start_Tr;
	  print start_td;
	  print h2("Directly manage tables:");
	  print start_ul;
	  foreach my $t ( @::Tables ) {
		  print li(a({-href=>"manage.cgi?table=$t->{'table'}"}, $t->{'heading'}));
	  }
	  print end_ul;
	  print start_td({-valign=>"top"}),
	  h2("Operator functions"),
	  ul(
	     li(a({ -href => "dump_database.cgi" }, "Backup database")), "\n",
	     li(a({ -href => "manage.cgi?op=check"}, "Compare DB to program metadata")), "\n",
	     li(a({ -href => "show_tables.cgi" }, "Show DB schema")), "\n",
	     
	     );
	  print h2("Test & debug scripts"), "\n",
	  ul(
	     li(a({ -href => "test/env.cgi" }, "Display environment variables")), "\n",
	     li(a({ -href => "test/db.cgi" }, "Test database")), "\n",
	     li(a({ -href => "test/ui.cgi" }, "Test Layout procedures")), "\n",
	     li(a({ -href => "test/app.cgi" }, "Display application converters")), "\n",
	     ), "\n";
	  print h2("Schema maintenance (current version: $version)");
	  
	  print start_ul;
	  
	  if ( opendir D,"maintenance" ) {
	      foreach my $f ( sort grep /^update[0-9]*.sql$/, readdir D ) {
		  my $vers = $f;
		  $vers =~ s/[^0-9]*([0-9]*).*/$1/;
		  my $versm1 = $vers-1;
		  print li(a({-href=>"db_update.cgi?sql=maintenance/$f&version=$versm1"}, "Update #$vers"),
			   ($vers>$version? " (not done)" : " (done)"));
	      }
	      closedir D;
	  }
	  print end_ul, end_td;
	  print end_Tr;
	  print end_table;
	  
	  print end_table;
	  
	  
      };
	
	print Footer(self_url());
	print end_html;
}


