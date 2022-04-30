#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);
use Getopt::Std;
use CGI qw(:standard -nosticky *table *Tr *ul *li);
use Mail::Mailer;

require "globals.pl";

use InterviewTable;
use ParamTable;
use DepartmentTable;
use OpeningTable;

use Application;
use Query;
use Database;
use Layout;
use Candidate;
use Utility;


Application::Init();

if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "weekly" and do {
          doWeekly();
          last SWITCH;
      };
      $op eq "mail" and do {
	  doMail();
	  last SWITCH;
      };
      $op eq "counts" and do {
	  doCounts();
	  last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
    print header;
    print start_html({-title=>"Reports"});
    print p("Shouldn't get here.");
    print end_html;
}

sub doMail
{
    ConnectToDatabase();
    print header;
    print doHeading({-title=>"Send Reminders"});;
    my $where = "remind = " . SQLQuote("Y");
    my @people = getRecordsMatch({-table=>\%::UserTable,
				  -column=>['sendmail', 'active'],
				  -value=>['Y', 'Y']});
    
    foreach my $p ( @people ) {
	
	my $hash = {
	    -status=>['NEW', 'ACTIVE'],
	    -owner=>[$$p{'id'}],
	};
	my ($query,$hashes) = Query::constructQuery($hash);
	
	my $doquery = fullURL("query.cgi" . Query::makeURL($hash));
	
	my @results = Query::extendedResults($query, $hashes);
	if ( scalar(@results) == 0 ) {
	    next;
	}
	
	print p(b("Sending to $$p{'name'} ($$p{'email'})"));
	## Mail the note
	
	my $from = getValueMatch({
	    -table=>\%::ParamTable,
	    -column=>"name",
	    -equals=>"e-mail-from",
	    -return=>"value",
	});
	if ( !defined $from ) {
	    $from = $::EMAIL_FROM;
	}
	my $msg = new Mail::Mailer('sendmail');
	my $boundary = "**__**__**__**__**__";
	
	my %headers = (
		       'From' => $from,
		       'To' => $$p{'email'},
		       'Subject' => "Tracker Reminder: Candidates owned by you",
		       'MIME-Version' => '1.0',
		       'Content-Type' => 'multipart/mixed;boundary="' . $boundary . '"',
		       );
	
	
	$msg->open(\%headers);
	
	print $msg "The following candidates are owned by you:\n\n";
	print $msg sprintf("%20.20s  %-8.8s  %-8.8s  %s\n", "NAME", "STATUS", "AGE", "NEXT ACTION");
	print $msg sprintf("%20.20s  %-8.8s  %-8.8s  %s\n", "----", "------", "---", "-----------");
	foreach my $r ( @results ) {
	    print $msg sprintf("%20.20s  %-8.8s  %-8.8s  %s\n",$$r{'name'}, $$r{'status'}, $$r{'agestr'}, $$r{'action_id.action'});
	}
	print $msg "--$boundary\n";
	
	my $m = new CGI;
	print $msg $m->header;
	
	print $msg $m->p("The following candidates are NEW or ACTIVE and owned by you, $$p{'name'}:");
	
	print $msg $m->start_table({-width=>"100%", -cellspacing=>"0", -cellpadding=>"2"});
	print $msg $m->Tr(
			  $m->td($m->b("Name")), "\n",
			  $m->td($m->b("Status")), "\n",
			  $m->td($m->b("Next Action")), "\n",
			  $m->td($m->b("Age")), "\n",
			  $m->td($m->b("Position")), "\n",
			  );
	my $row = 0;
	my $color;
	print start_ul;
	foreach my $r ( @results ) {
	    if ( $row%2 ) {
		$color = "#ffffff";
	    } else {
		$color = "#ddffdd";
	    }
	    $row++;
	    my $link = candidateLink({-id=>$r->{'id'}, -name=>$r->{'name'}});
	    print $msg $m->Tr(
			      $m->td({-bgcolor=>$color}, $r->{'name'} ? a({-href=>$link}, $r->{'name'}) : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'status'} ? $r->{'status'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'action_id.action'} ? $r->{'action_id.action'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'agestr'} ? $r->{'agestr'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'opening_id.description'} ? $r->{'opening_id.description'} : "&nbsp;" ), "\n",
			      );
	    print li(candidateLink({-name=>$r->{'name'},-id=>$r->{'id'}}), " - ", $r->{'action_id.action'});
	}
	print end_ul;
	print $msg $m->end_table, "\n";
	print $msg $m->a({-href=>$doquery},
			 $m->p(scalar(@results) . " result" . (scalar(@results)!=1?"s.":"."))), "\n";
	
	print $msg "\n--$boundary--\n";
	
	$msg->close;         # complete the message and send it
	
    }
    print end_html;
}


sub doWeekly
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Reports"});
    my $weekdelta = param("weeks") ? param("weeks") : 0;;
    
    ## Find the beginning and end of this week
    
    my ($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday, $isdst);
    my $back = 0;
    do {
	($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time-(-$weekdelta*7+$back)*24*60*60);
	$back ++;
    } until ( $wday == 0 );
    my $sunday = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $mday);
    
    my $forward = 0;
    do {
	($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time+($weekdelta*7+$forward)*24*60*60);
	$forward++;
    } until ( $wday == 6 );
    my $saturday = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $mday);
    
    ## dojoin is "2" here to join from Interview to Canidate to Opening
    
    my @interviews = getRecordsWhere({-table=>\%::InterviewTable,
				      -where=>"date BETWEEN " . SQLQuote($sunday) . " AND " . SQLQuote($saturday),
				      -dojoin=>2});
    
    my $active = fullURL("query.cgi?op=query;status=NEW;status=ACTIVE;name=;sort=actionorder-n");
    print start_ul, "\n";
    print li(a({-href=>"$active"}, "Current candidate funnel"));
    print li("Interviews this week ($sunday through $saturday):"), "\n";
    print start_ul, "\n";
    foreach my $r ( @interviews ) {
	print start_li;
	print "$r->{'date'}: ";
	print candidateLink({-id=>$r->{'candidate_id'},
			     -name=>$r->{'candidate_id.name'}});
	print " ($r->{'candidate_id.opening_id.description'})";
	if ( $r->{'candidate_id.status'} eq "REJECTED" ) {
	    print " - REJECTED";
	} else {
	    print ul(li("Next action: $r->{'candidate_id.action_id.action'}"));
	}
	print end_li;
    }
    print end_ul, "\n";
    
    print end_ul, "\n";
    
    print hireRatio();
    print Footer(self_url(-absolute=>1));
    print end_html;
}


sub doCounts
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Candidates by Position and Status"});
    
    ##
    ## structures used in this report:
    ##  @categories - array of all entries from the action_category table
    ##  %actionMap = maps action categories into an array of action PKs
    ##
    
    my @categories = getAllRecords({-table=>\%::ActionCategoryTable});
    my %actionIdMap;
    my %actionMap;
    foreach my $cat ( @categories ) {
	my @catactions = getRecordsMatch({-table=>\%::ActionTable,
					  -column=>"category_id",
					  -value=>$cat->{'id'}});
	foreach my $ca ( @catactions ) {
	    push @{$actionMap{$cat->{'name'}}}, $ca;
	    push @{$actionIdMap{$cat->{'name'}}}, $ca->{'id'};
	}
    }
#	print Utility::ObjDump(\%actionIdMap);

    my %depts = getRecordMap({-table=>\%::DepartmentTable});
    foreach my $d ( sort {$depts{$a}{'name'} cmp $depts{$b}{'name'}} keys %depts ) {
	my @positions = getRecordsMatch({-table=>\%::OpeningTable,
					 -column=>"department_id",
					 -value=>$depts{$d}{'id'}});
	if ( scalar(@positions) == 0 ) {
	    next;
	}
	print h2("$depts{$d}{'name'}");
	print start_table({-width=>"100%", -cellpadding=>4, -cellspacing=>0, -border=>1});
	print start_Tr;
	print td(b("Position"));
	foreach my $cat ( @categories ) {
	    print td({-align=>"center"}, b($cat->{'name'}));
	}
	print end_Tr;
	my %catsums;
	foreach my $p ( @positions ) {

	    print start_Tr;
	    print td($$p{'description'});
	    my %catcounts;
	    foreach my $cat ( @categories ) {
		my $hash = {
		    -status=>['NEW', 'ACTIVE'],
		    -action=>$actionIdMap{$cat->{'name'}},
		    -opening=>[$p->{'id'}],
		    -nohide=>1,
		};
		my ($query,$hashes) = Query::constructQuery($hash);
		my $doquery = fullURL("query.cgi" . Query::makeURL($hash));
		$catcounts{$cat->{'name'}}{'count'} = Query::countResults($query, $hashes);
		$catcounts{$cat->{'name'}}{'query'} = $doquery;
		$catsums{$cat->{'name'}}{'count'} += $catcounts{$cat->{'name'}}{'count'};
	    }

	    my ($query,$hashes,$count,$hash,$url, @results);

	    undef $hash;
	    $hash = {
		-status => ['HIRED'],
		-action=>$actionIdMap{'hired'},
		-opening=>[$p->{'id'}],
		-nohide=>1,
	    };
	    ($query,$hashes) = Query::constructQuery($hash);
	    $url = fullURL("query.cgi" . Query::makeURL($hash));
	    $count = Query::countResults($query, $hashes);
	    if ( $count ) {
		$catcounts{'hired'}{'count'} += $count;
		$catcounts{'hired'}{'query'} = $url;
		$catsums{'hired'}{'count'} += $count;
	    }
	    
	    ## Look for status == REJECTED

	    undef $hash;
	    $hash = {
		-status => ['REJECTED'],
		-opening=>[$p->{'id'}],
		-nohide=>1,
	    };
	    if ( exists $actionIdMap{'rejected'} && scalar @{$actionIdMap{'rejected'}} > 0 ) {
		$hash->{'-action'} = $actionIdMap{'rejected'};
	    }
	    ($query,$hashes) = Query::constructQuery($hash);
	    $url = fullURL("query.cgi" . Query::makeURL($hash));
	    $count = Query::countResults($query, $hashes);
	    if ( $count ) {
		$catcounts{'rejected'}{'count'} += $count;
		$catcounts{'rejected'}{'query'} = $url;
		$catsums{'rejected'}{'count'} += $count;
	    }
	    
	    foreach my $cat ( @categories ) {
		print td({-align=>"center"},
			 (exists $catcounts{$cat->{'name'}} && $catcounts{$cat->{'name'}}{'count'}) ?
			 a({-href=>$catcounts{$cat->{'name'}}{'query'}}, $catcounts{$cat->{'name'}}{'count'}) : "&nbsp;");
	    }
	    print end_Tr;

	}
	print start_Tr;
	print td(b("Totals"));
	foreach my $cat ( @categories ) {
	    print td({-align=>"center"},
		     (exists $catsums{$cat->{'name'}} && $catsums{$cat->{'name'}}{'count'}) ?
		     $catsums{$cat->{'name'}}{'count'} : "&nbsp;");
	}
	print end_Tr;
	
	print end_table;
    }

    print h2("Categories"), start_ul;
    foreach my $cat ( @categories ) {
	print li(b($cat->{'name'}));
	print start_ul;
	foreach my $ca ( @{$actionMap{$cat->{'name'}}} ) {
	    print li($ca->{'action'});
	}
	print end_ul;
    }
    print end_ul;
    
    print Footer(), end_html;
}



sub hireRatio
{

    my ($t0, $t1);
    ## six  weeks ago
    {
	my ($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time-42*24*60*60);
	$t0 = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $mday);
    };
    {
	my ($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time);
	$t1 = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $mday);
    };
    my @interviews = getRecordsWhere({-table=>\%::InterviewTable,
				      -where=>"date BETWEEN " . SQLQuote($t0) . " AND " . SQLQuote($t1),
				      -dojoin=>2});

    
    return "";
}

