#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);
use CGI::Carp qw(fatalsToBrowser);;

use Calendar;

use Application;
use Layout;
use Database;
use Utility;
use Schedule;
use Login;

require "globals.pl";
use InterviewTable;
use CandidateTable;
use OpeningTable;
use DepartmentTable;

Application::Init();


# In must-log-in mode, make sure we're logged in

my $mustLogIn = Param::getValueByName('must-log-in');
if ( $mustLogIn && ref $mustLogIn ) {
    $mustLogIn = $mustLogIn->{'value'};
}
if ( $mustLogIn && !isLoggedIn() ) {
    doMustLogin(url(-absolute => 1, -query=>1));;
}

##
## This hash defines what is different from type to type of calendar
##

my %TypeTable = (
	'interview' => {
		'heading' => "Interviews",
		'data' => \&Schedule::getCandidatesByDate,
		'begin' => -14,
		'end' => 14,
	},
	'user' => {
		'heading' => "Users",
		'data' => \&Schedule::getCandidatesByDate,
		'begin' => -14,
		'end' => 14,
	},
	'candidate' => {
		'heading' => 'Candidates',
		'data' => \&Candidate::getCandidatesByDate,
		'begin' => -42,
		'end' => 1,
	},
	);


my $smallWeekends = 1;
my $grayWeekends = 1;

my $default_type = "interview";

my $type = defined param("type") ? param("type") : $default_type;
if ( !exists $TypeTable{$type} ) {
	$type = $default_type;
}



my ($today_seconds, $today_minutes, $today_hours, $today_day_of_month, $today_month, $today_year,
	$today_wday, $today_yday, $today_isdst) = localtime(time);

my $NumCancelled = 0;


if ( defined param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "setup" and do {
          doSetup();
          last SWITCH;
      };
      $op eq "go" and do {
          doGo();
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
    print header;

    print doHeading({-title=>"Make a Calendar: $TypeTable{$type}{'heading'}",
		     -script=>{-language=>'JavaScript',
			       -src=>'javascript/date_picker.js'}}), "\n";
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime(time + $TypeTable{$type}{'begin'}*24*60*60);
	my $begin = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $day_of_month);
    ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime(time + $TypeTable{$type}{'end'}*24*60*60);
	my $end = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $day_of_month);
    
  BODY: {		
      print Layout::startForm({-name=>"form"}), "\n";
      print table({-border=>"1"},
		  Tr(
		     td({-align=>"right"}, "Start date: "), "\n",
		     td(textfield({-name=>"start", -size=>"12", -default=>$begin}),
			a({-href=>"javascript:show_calendar('form.start');"},
			  img({-src=>"images/show_calendar.gif", -border=>"0"}))), "\n",
		     ), "\n",
		  Tr(
		     td({-align=>"right"}, "End date: "), "\n",
		     td(textfield({-name=>"end", -size=>"12", -default=>$end}),
			a({-href=>"javascript:show_calendar('form.end');"},
			  img({-src=>"images/show_calendar.gif", -border=>"0"}))), "\n",
		     ), "\n",
		  Tr(
		     td({-align=>"right"}, "Small weekend days: "), "\n",
		     td(checkbox({-name=>"smallweekends", -checked=>"1", -value=>"1", -label=>""}))
		     ), "\n",
		  Tr(
		     td({-align=>"right"}, "Gray weekend days: "), "\n",
		     td(checkbox({-name=>"grayweekends", -checked=>"1", -value=>"1", -label=>""}))
		     ), "\n",
		  ), "\n";
      print hidden({-name=>"op", -default=>"setup"}), "\n";
	  print hidden({-name=>"type", -default=>$type});
      print submit({-name=>"Create Calendar"}), Layout::endForm, "\n";
  };
    print Footer({-url=>url(-absolute => 1, -query=>1)}), end_html, "\n";
}

use Date::Manip qw(ParseDate UnixDate);

sub doSetup
{
	my $q = new CGI;
	$q->param("op", "go");
	$q->delete("Create Calendar");
	$q->delete("Search");
	print $q->redirect(-location=>$q->url(-absolute => 1, -query=>1), -method=>"get");
}

sub doGo
{
    print header;
    
    ConnectToDatabase();
    
    print doHeading({-title=>"Interviewing Calendar: $TypeTable{$type}{'heading'}"}), "\n";

    my $calendar = new Calendar({
	-startdate => param("start"),
	-enddate => param("end"),
	-smallweekends => param("smallweekends") ? 1 : 0,
	-grayweekends => param("grayweekends") ? 1 : 0,
	-type => $type,
	-func => $TypeTable{$type}{'data'},
    });

    print $calendar->render();

#    if ( $type eq "user" ) {
#	print h2("Users during this period");
#	print start_table;
#	print Tr(
#		 td({-align=>"right"}, b("Name")),
#		 td(b("Number")),
#		 );
#	foreach my $p ( sort {$AllUsers{$b} <=> $AllUsers{$a}} keys %AllUsers ) {
#	    print Tr(
#		     td({-align=>"right"}, $p),
#		     td({-align=>"left"}, $AllUsers{$p}),
#		     );
#	}
#	print end_table;
#    }
    print Footer({-url=>url(-absolute => 1, -query=>1)}), end_html, "\n";
}




