#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);
use CGI::Carp;

require "globals.pl";
use FrontlinkTable;

use Param;

use Layout;
use Login;
use Database;
use Application;

Application::Init();

print header;


doFirstPage();
exit(0);

sub doFirstPage
{
    if ( -r "SHUTDOWN" ) {
	print start_html;
	print p("candidate tracker is down for maintenance - back soon!");
	print end_html;
	exit(0);
    }
    my $self_url = self_url();
#    Utility::setHTMLErrors(0);
    ConnectToDatabase() || Utility::preHTMLAbort("Cannot connect to Database");
    
  BODY: {
      my $title = Param::getValueByName("title");
      my $image = Param::getValueByName("image");
      my $mustLogIn = Param::getValueByName('must-log-in');
      my $canCreateAccount = Param::getValueByName('can-create-account');

      if ( !defined $title ) {
	  $title = "Candidate Tracker";
      }
      if ( !defined $image ) {
	  $image = "images/help.gif";
      }
      print doHeading({-title=>$title} ), "\n";

      Application::checkParams();

      print start_table({ -border=>"0", -cellpadding=>"8", -cellspacing=>"0"}), "\n";
      print start_Tr;
      print td(img({-src=>$image}));
      print start_td({-valign=>"top"});
      if ( isLoggedIn() && isAdmin() ) {
	  print ul(
	      li(a({-href=>"reports.cgi?op=mail"}, "Send e-mail reminders")),
	      li(a({ -href => "maintenance.cgi" }, "DB Maintenance")), "\n",
	      ul(
		  li(a({ -href => "manage.cgi?table=opening" }, "Manage Job Openings")), "\n",
		  li(a({ -href => "manage.cgi?table=user" }, "Manage Users")), "\n",
		  li(a({ -href => "manage.cgi?table=recruiter" }, "Manage Recruiters")), "\n",
		  
	      ),
	      );
      } 
      if ( $mustLogIn && isLoggedIn() ) {
	  my $query = 'select count(*),status from candidate group by status';
	  SQLSend($query);
	  print p(b("Candidates:")), start_ul;
	  my $total = 0;
	  while( my($count,$status) = SQLFetchData() ) {
	      print li(a({-href=>"query.cgi?op=query;status=$status"}, "$count in $status status"));
	      $total += $count;
	  }
	  if ( $total == 0 ) {
	      print li("None.");
	  }
	  print end_ul;
      } 
      if ( isLoggedIn()) {
          if ( isAdmin() ) {
              print ul(li(a({-href=>"user.cgi"}, font({-size=>"4"}, "Manage user accounts"))));
          } else {
              print ul(li(a({-href=>"user.cgi"}, font({-size=>"4"}, "Manage your login"))));
          }
      }
      
      print end_td;
      
      print end_Tr;
      
      
      print start_Tr;
      print start_td;
      print start_ul;
      if ( $mustLogIn && isLoggedIn() ) {
	  print li(a({-href => "query.cgi" }, font({-size=>"4"},"Advanced Search"))), "\n",
	  li(a({-href=>"candidates.cgi?op=add"}, font({-size=>"4"}, "Add a candidate"))), "\n";
      }
      if ( isLoggedIn() ) {
	  my $name = getLoginName();
	  my $mylist = "query.cgi?op=query;status=NEW;status=ACTIVE;owner_id=" . getLoginId();
	  print li(a({-href=>$mylist}, font({-size=>"4"}, "Candidates owned by $name")));
      } else {
	  my @self_url = self_url();
	  print li(a({-href=>"loginout.cgi?link=$self_url"}, font({-size=>"4"}, "Log in")));
      }

      print end_ul;

      if ( $mustLogIn && isLoggedIn() ) {

	  # Search for a name

	  print Layout::startForm({-action=>"query.cgi"}), "\n",
	  hidden({-name=>"op", -default=>"go"}), "\n",
	  "Search for a name: ", "\n",
	  textfield({-name=>"name", -size=>"18"}), "\n",
	  submit({-name=>"Search"}), "\n",
	  Layout::endForm;
      }

      print end_td;

      print start_td({-valign=>"top"});
      
      if ( $mustLogIn && isLoggedIn() ) {
	  print ul(
	      li(a({-href=>"reports.cgi?op=openings;hidesql=1"}, font({-size=>"4"}, "List all openings"))),
	      li(a({-href=>"reports.cgi?op=weekly"},
		   font({-size=>"4"}, "Weekly report"),
		   " ", a({-href=>"reports.cgi?op=weekly&weeks=-1"}, "(last week)")),
		 " ", a({-href=>"reports.cgi?op=weekly&weeks=-1&weeks=0"}, "(both)")),
	      li(a({-href=>"reports.cgi?op=counts;hidesql=1"}, font({-size=>"4"}, "Counts per position"))),
	      li(font({-size=>"4"}, "Calendar: ",
		      a({-href=>"calendar.cgi?type=interview"},"interviews"), "\n", " or ",
		      a({-href=>"calendar.cgi?type=user"}, "interviewers"), "\n", " or ",
		      a({-href=>"calendar.cgi?type=candidate"}, "candidates"))),
	      li(font({-size=>"4"}, a({-href=>"manage.cgi?op=list;table=recruiter"}, "List recruiters"))),
	      );
      }

      # Create a new account

      if ( $canCreateAccount && !isLoggedIn() ) {
	  print ul(li("New? ",
		      a({href=>"create-account.cgi"}, "Create yourself an account")));
      }
      
      print end_td;
      print end_Tr, end_table;
      
      SQLSend("SELECT COUNT(*) from frontlink");
      my $links = SQLFetchOneColumn();
      if ( $links > 0 ) {
	  print h2("Related Links"), "\n";
	  my $tbl = \%::FrontlinkTable; #to suppress spurious warning
	  my @links = getAllRecords({-table=>\%::FrontlinkTable});
	  
	  print start_table();
	  print start_Tr;
	  print start_td({-valign=>"top"});
	  
	  foreach my $rec ( @links ) {
	      if ( $rec->{side} eq "LEFT" ) {
		  print a({-href=>$rec->{url}}, $rec->{description}), br;
	      }
	  }
	  print end_td;

	  print td({-width=>64});
	  print start_td({-valign=>"top"});
	  
	  foreach my $rec ( @links ) {
	      if ( $rec->{side} eq "RIGHT" ) {
		  print a({-href=>$rec->{url}}, $rec->{description}), br;
	      }
	  }
	  print end_td;
	  
	  print end_Tr;
	  print end_table;
      }
      if ( isLoggedIn() ) {
	  if ( isAdmin() || Param::getValueByName("frontlinks-anyone") eq "Y" ) {
	      print p(a({-href=>'manage.cgi?table=frontlink'}, "Add quicklinks here.")), "\n";
	  }
      }


  };
    
    print Footer({-url=>"$self_url"});
    
    print end_html;
}

