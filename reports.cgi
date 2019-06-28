#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);
use Getopt::Std;
use CGI qw(:standard -nosticky *table *Tr *ul *li *ol);
use Mail::Mailer;
use Data::Dumper;

require "globals.pl";

use Calendar;

use InterviewTable;
use ParamTable;
use DepartmentTable;
use OpeningTable;

use Application;
use Query;
use Database;
use Layout;
use Candidate;
use Department;
use Schedule;
use Utility;
use Login;

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
      $op eq "openings" and do {
	  doOpenings();
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
    my $stdout = "";

    $stdout .= header;
    $stdout .= doHeading({-title=>"Send Reminders"});;
    my $where = "remind = " . SQLQuote("Y");
    my @people = getRecordsMatch({-table=>\%::UserTable,
				  -column=>['sendmail', 'active'],
				  -value=>['Y', 'Y']});
    
    my $from = Param::getValueByName("e-mail-from");
    if ( !defined $from ) {
	$from = $::EMAIL_FROM;
    }

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
	
	$stdout .= p(b("Sending to $$p{'name'} ($$p{'email'})"));

	## Mail the note
	
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
	$stdout .= start_ul;
	foreach my $r ( @results ) {
	    if ( $row%2 ) {
		$color = "#ffffff";
	    } else {
		$color = "#ddffdd";
	    }
	    $row++;
	    my $link = candidateLink({-id=>$r->{'id'}, -name=>$r->{'name'}});
	    print $msg $m->Tr(
			      $m->td({-bgcolor=>$color}, $r->{'name'} ? $link : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'status'} ? $r->{'status'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'action_id.action'} ? $r->{'action_id.action'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'agestr'} ? $r->{'agestr'} : "&nbsp;" ), "\n",
			      $m->td({-bgcolor=>$color}, $r->{'opening_id.description'} ? $r->{'opening_id.description'} : "&nbsp;" ), "\n",
			      );
	    $stdout .= li(candidateLink({-name=>$r->{'name'},-id=>$r->{'id'}}), " - ", $r->{'action_id.action'});
	}
	$stdout .= end_ul;
	print $msg $m->end_table, "\n";
	print $msg $m->a({-href=>$doquery},
			 $m->p(scalar(@results) . " result" . (scalar(@results)!=1?"s.":"."))), "\n";
	
	print $msg "\n--$boundary--\n";
	
	$msg->close;         # complete the message and send it
	
    }
    $stdout .= end_html;
    if ( param("mailto") ) {
	my $msg = new Mail::Mailer('sendmail');
	my $boundary = "**__**__**__**__**__";
	
	my %headers = (
		       'From' => $from,
		       'To' => param("mailto"),
		       'Subject' => "Tracker Reminder emails sent",
		       'MIME-Version' => '1.0',
		       'Content-Type' => 'multipart/mixed;boundary="' . $boundary . '"',
		       );
	
	$msg->open(\%headers);
	print $msg "This is a MIME-encoded HTML message\n";
	print $msg "--$boundary\n";

	print $msg $stdout;
	print $msg "\n--$boundary--\n";
	
	$msg->close;         # complete the message and send it
    } else {
	print $stdout;
    }
    print Footer();
    print end_html;
}


sub doWeekly
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Reports", -noheading=>1});
    print h1("Weekly Candidate Status"), hr(), "\n";

    my @weeks = param("weeks") ? param("weeks") : ( 0 );
    foreach my $weekdelta ( @weeks ) {
	my $subheading;
	if ( $weekdelta == 0 ) {
	    $subheading = "This Week";
	} elsif ( $weekdelta == -1 ) {
	    $subheading = "Last Week";
	} elsif ( $weekdelta < 0 ) {
	    $subheading = 0-$weekdelta . " Weeks Ago";
	} elsif ( $weekdelta == 1 ) {
	    $subheading = "One Week From Now";
	} else {
	    $subheading = "$weekdelta Weeks From Now";
	}

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
	my @departments = Department::getAllDepartments();

    #    Utility::ObjDump(\@interviews);

	print h2("$subheading: $sunday to $saturday"), "\n";
	
	if ( param("highlights") ) {
	    print h3("Highlights/Lowlights");
	    print ol(li("Item one"));
	}

	print h3("Calendar"), "\n";

	print p(a({-href=>Calendar::getURL({
	    -startdate=>$sunday,
	    -enddate=>$saturday,
	    -grayweekends=>1,
	    -smallweekends=>1,
	})}, "Click here for the latest calendar information"));

	my $calendar = new Calendar({
	    -startdate => $sunday,
	    -enddate => $saturday,
	    -smallweekends => 0,
	    -grayweekends => 1,
	    -type => "interview",,
	    -func => \&Schedule::getCandidatesByDate,
	});

	print $calendar->render();

	print h3("Detailed Activity"), "\n";

	foreach my $dept ( @departments ) {
	    my $active = fullURL("query.cgi?op=query;status=NEW;status=ACTIVE;name=;department_id=" .
				 $dept->{'id'} . ";sort=actionorder-n");
	    print h4(Department::getName($dept)), "\n";
	    print start_ul, "\n";
	    print li(a({-href=>"$active"}, "Current candidate funnel"));
	    my $no_text_yet = 1;
	    foreach my $r ( @interviews ) {
		if ( $r->{'candidate_id.opening_id.department_id'} != $dept->{'id'} ) {
		    next;
		}
		if ( $no_text_yet ) {
		    print li("Interviews this week ($sunday through $saturday):"), "\n";
		    print start_ul, "\n";
		    $no_text_yet = 0;
		}
		print start_li;
		print "$r->{'date'}: ";
		print candidateLink({-id=>$r->{'candidate_id'},
				     -name=>$r->{'candidate_id.name'}});
		print " ($r->{'candidate_id.opening_id.description'})";
		if ( $r->{'candidate_id.status'} eq "REJECTED" ) {
		    print " - REJECTED";
		}
		print start_ul;
		my $interviewers = Schedule::getInterviewers($r->{'id'});
		print li( "Interviewed by: ", join ", ", map { User::getName($_) } keys %$interviewers);
		if ( $r->{'candidate_id.status'} ne "REJECTED" ) {
		    print li("Next action: $r->{'candidate_id.action_id.action'}");
		}

		print end_ul;
		print end_li;
	    }
	    if ( !$no_text_yet ) {
		print end_ul, "\n";
	    } else {
		print li("No activity in this time period");
	    }

	    print end_ul, "\n";
	}	
    }
#    print hireRatio();
#    print Footer(self_url());
    print end_html;
}


sub doCounts
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Candidates by Position and Status"});

    ##
    ## if the "hidesql" parameter is set, pass it to the Footer formatter
    ## This is done here because, for this page, the SQL is very long and takes a lot
    ## of time to download to the browser.
    ##

    my $hidesql = 0;
    if ( param("hidesql") ) {
        $hidesql = 1;
    }

    my $dounaccounted = 0;
    my @counted = ();
    if ( param("unaccounted") ) {
        $dounaccounted = 1;
    }

    ##
    ## Keeps track of footnotes
    ##

    my @notes;

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

    my $grand_total;
    my @grand_wheres;
    my %depts = getRecordMap({-table=>\%::DepartmentTable});
    foreach my $d ( sort {$depts{$a}{'name'} cmp $depts{$b}{'name'}} keys %depts ) {
	my @positions = getRecordsMatch({-table=>\%::OpeningTable,
					 -column=>["department_id", "status"],
					 -value=>[$depts{$d}{'id'}, 'OPEN']});
	if ( scalar(@positions) == 0 ) {
	    next;
	}
	print h2({-class=>"reports"},"$depts{$d}{'name'}"), "\n";
	print start_table({-width=>"100%", -cellpadding=>4, -cellspacing=>0, -border=>1}), "\n";

	my $countcolumns = scalar @categories + 3;
	my $total_countcolumns_percent = 60;
	my $countcolumn_size = $total_countcolumns_percent / $countcolumns;
	my $spanned_countcolumn_size = (scalar @categories) * $countcolumn_size;

	my $namecolumn_size = (100 - $total_countcolumns_percent) * 3 / 4;
	my $duedatecolumn_size = (100 - $total_countcolumns_percent) * 1 / 4;

        ## Table heading row 1

	print start_Tr({-class=>"reports"}), "\n";
	print td({-rowspan=>"2", -width=>"$namecolumn_size%"}, b("Position")), "\n";
	print td({-rowspan=>"2", -width=>"$duedatecolumn_size%"}, b("Due Date")), "\n";
        print td({-colspan=>scalar @categories, -align=>"center", -width=>"$spanned_countcolumn_size%"}, b("New or Active")), "\n";
        print td({-rowspan=>"2", -align=>"center", -width=>"$countcolumn_size%"}, b("Hired")), "\n";
        print td({-rowspan=>"2", -align=>"center", -width=>"$countcolumn_size%"}, b("Rejected"), br,
                 a({-href=>"#note1"}, font({-size=>"1"}, "(see note 1)"))), "\n";
    $notes[1] = "Rejected status include candidates with status of REJECTED, CLOSED, or SHELVED";
        print td({-rowspan=>"2", -align=>"center", -width=>"$countcolumn_size%"}, b("Other")), "\n";
	print end_Tr, "\n";

        ## Table heading row 2

        print start_Tr({-class=>"reports"}), "\n";
	foreach my $cat ( @categories ) {
	    print td({-align=>"center", -width=>"$countcolumn_size%"}, b($cat->{'name'})), "\n";
	}
        print end_Tr, "\n";

        my @display_categories = ();
        foreach my $cat ( @categories ) {
            push @display_categories, $cat->{'name'};
        }
        push @display_categories, 'hired';
        push @display_categories, 'rejected';
        push @display_categories, 'other';


	my %catsums;
	foreach my $p ( @positions ) {

	    print start_Tr, "\n";
	    print td($$p{'description'}), "\n";
	    print td($$p{'duedate'}), "\n";
	    my %catcounts;
            my @wheres = ();
	    foreach my $cat ( @categories ) {
		my %hash = (
		    -status=>['NEW', 'ACTIVE'],
		    -action=>$actionIdMap{$cat->{'name'}},
		    -opening=>[$p->{'id'}],
		    -nohide=>1,
		);
                my %hash2 = %hash;
                delete $hash2{'-opening'};

		my ($query,$hashes) = Query::constructQuery(\%hash);
		my $doquery = fullURL("query.cgi" . Query::makeURL(\%hash));
                push @wheres, Query::makeWhereClause(\%hash2);

                $catcounts{$cat->{'name'}}{'count'} = Query::countResults($query, $hashes);
		$catcounts{$cat->{'name'}}{'query'} = $doquery;
		$catsums{$cat->{'name'}}{'count'} += $catcounts{$cat->{'name'}}{'count'};
	    }

	    my ($query,$hashes,$count,$hash,$url, @results);

	    my %hash = (
		-status => ['HIRED'],
#		-action=>$actionIdMap{'hired'},
		-opening=>[$p->{'id'}],
		-nohide=>1,
	    );
            my %hash2 = %hash;
            delete $hash2{'-opening'};

	    ($query,$hashes) = Query::constructQuery(\%hash);
	    $url = fullURL("query.cgi" . Query::makeURL(\%hash));
            push @wheres, Query::makeWhereClause(\%hash2);
            $count = Query::countResults($query, $hashes);

	    if ( $count ) {
		$catcounts{'hired'}{'count'} += $count;
		$catcounts{'hired'}{'query'} = $url;
		$catsums{'hired'}{'count'} += $count;
	    }
	    
	    ## Look for status == REJECTED

	    %hash = (
		-status => ['REJECTED', 'SHELVED', 'CLOSED'],
		-opening=>[$p->{'id'}],
		-nohide=>1,
	    );
            %hash2 = %hash;
	    if ( exists $actionIdMap{'rejected'} && scalar @{$actionIdMap{'rejected'}} > 0 ) {
		$hash->{'-action'} = $actionIdMap{'rejected'};
	    }
	    ($query,$hashes) = Query::constructQuery(\%hash);
	    $url = fullURL("query.cgi" . Query::makeURL(\%hash));
            delete $hash2{'-opening'};
            push @wheres, Query::makeWhereClause(\%hash2);
            $count = Query::countResults($query, $hashes);
	    if ( $count ) {
		$catcounts{'rejected'}{'count'} += $count;
		$catcounts{'rejected'}{'query'} = $url;
		$catsums{'rejected'}{'count'} += $count;
	    }

	    ## Find the unaccounted items in this position

            push @grand_wheres, @wheres;

            ## Find all of the candidates that were not selected by any
            ## of the where clauses collected for this position so far

            my $where = CombineAndNegateWheres(\@wheres,$p);
            my @pks = Database::getPKsWhere({
                -table=>\%::CandidateTable,
                -where=>$where,
            });
            $count = scalar(@pks);
	    if ( $count ) {
		$catcounts{'other'}{'count'} += $count;
		$catcounts{'other'}{'query'} = fullURL("query.cgi?op=query;pks=" . join(",", @pks));
		$catsums{'other'}{'count'} += $count;
	    }

	    foreach my $cat ( @display_categories ) {
		print td({-align=>"center"},
			 (exists $catcounts{$cat} && $catcounts{$cat}{'count'}) ?
			 a({-href=>$catcounts{$cat}{'query'}}, $catcounts{$cat}{'count'}) : "&nbsp;"), "\n";
	    }
	    print end_Tr, "\n";
#            print Tr(td($where));

	}
        my $department_total = 0;
	print start_Tr, "\n";
	print td({-colspan=>"2"}, b("Totals")), "\n";
	foreach my $cat ( @display_categories ) {
	    print td({-align=>"center"},
		     (exists $catsums{$cat} && $catsums{$cat}{'count'}) ?
		     $catsums{$cat}{'count'} : "&nbsp;");
            $department_total += $catsums{$cat}{'count'};
	}
	print end_Tr, "\n";
	
	print end_table, "\n";
        print p(b($department_total," for department \"$depts{$d}{'name'}\""));
        $grand_total += $department_total;
    }

    ##
    ## Locate all of the candidates that were not selected by any of the
    ## where clauses anywhere above.
    ##

    my $where = CombineAndNegateWheres(\@grand_wheres);
    my @unaccounted_pks = Database::getPKsWhere({
        -table=>\%::CandidateTable,
        -where=>$where,
    });
    my $unaccounted_count = scalar(@unaccounted_pks);
    my $unaccounted_url = fullURL("query.cgi?op=query;pks=" . join(",", @unaccounted_pks));

    ##
    ## Print the summary counts
    ##

    print start_table({-border=>"0"}), "\n";
    
    print Tr(
             td({-align=>"right"},b($grand_total)), "\n",
             td(b(" total entries for all departments.")), "\n",
             );
    
    print Tr(
             td({-align=>"right"}, b(a({-href=>$unaccounted_url}, $unaccounted_count))), "\n",
             td(b(" candidates were not accounted for in the above table.")),
             ), "\n";

    print Tr(
             td({-align=>"right"}, b($unaccounted_count+$grand_total)), "\n",
             td(b("Total candidates in the tracker.")), "\n",
             ), "\n";
    print end_table, "\n";

    ##
    ## print notes
    #

    if ( scalar(@notes) > 0 ) {
        print h2("Notes");
        print start_ol;
        for (my $i=0;$i<scalar(@notes);$i++ ) {
            if ( $notes[$i] ) {
                print li({-value=>$i},a({-name=>"note$i"}, $notes[$i]));
            }
        }
        print end_ol;
    }
    

    ##
    ## Print, for each category of step in the process, which steps are in it.
    ##

    print h2("Categories"), start_ul, "\n";
    foreach my $cat ( @categories ) {
	print li(b($cat->{'name'})), "\n";
	print start_ul, "\n";
	foreach my $ca ( @{$actionMap{$cat->{'name'}}} ) {
	    print li($ca->{'action'}), "\n";
	}
	print end_ul, "\n";
    }
    print end_ul, "\n";
    
    my $args = {};
    if ( $hidesql ) {
        $args->{'hidesql'} = 1;
    }
    print Footer($args), end_html;
}

sub CombineAndNegateWheres
{
    my ($wheres,$position) = (@_);

    my $where = "NOT ( ";
    my $sep = "";
    foreach my $q ( @$wheres ) {
        $q =~ s/^\s*where\s*//i;
        $where .= $sep . "( $q )";
        $sep = " OR ";
    }
    $where .= " )";
    if ( $position ) {
        my %hash = (
                 -opening=>[$position->{'id'}],
                 );
        my $opening_clause =  Query::makeWhereClause(\%hash);
        $opening_clause =~ s/^\s*where\s*//i;
        $where .= " AND $opening_clause";
    }
    if (  !isAdmin() ) {
        $where .= " AND candidate.hide = " . SQLQuote(0);
    }
    return $where;
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

##
## doOpenings - a short report of openings
##

sub doOpenings
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Openings by Department"});

    ##
    ## if the "hidesql" parameter is set, pass it to the Footer formatter
    ## This is done here because, for this page, the SQL is very long and takes a lot
    ## of time to download to the browser.
    ##

    my $hidesql = 0;
    if ( param("hidesql") ) {
        $hidesql = 1;
    }

    my %depts = getRecordMap({-table=>\%::DepartmentTable});
    foreach my $d ( sort {$depts{$a}{'name'} cmp $depts{$b}{'name'}} keys %depts ) {
	my @positions = getRecordsMatch({-table=>\%::OpeningTable,
					 -column=>"department_id",
					 -value=>$depts{$d}{'id'}});
	if ( scalar(@positions) == 0 ) {
	    next;
	}
	print h2("$depts{$d}{'name'}"), "\n";
	print start_table({-cellpadding=>4, -cellspacing=>0, -border=>1}), "\n";

        ## Table heading row 1

	print start_Tr, "\n";
	print td(b("Req Number")), "\n";
	print td(b("Status")), "\n";
	print td(b("Priority")), "\n";
	print td(b("Due Date")), "\n";
	print td(b("Description")), "\n";
	print end_Tr, "\n";

	foreach my $p ( @positions ) {

	    print start_Tr, "\n";
	    my $openingLink = Opening::openingLink({-id=>$$p{'id'}, -name=>$$p{'number'}});
	    print td($openingLink ? $openingLink : "&nbsp;"), "\n";
	    print td($$p{'status'}), "\n";
	    print td({-align=>"center"}, $$p{'priority'} ? $$p{'priority'} : '&nbsp;' ), "\n";
	    print td($$p{'duedate'} ? $$p{'duedate'} : '&nbsp;' ), "\n";
	    print td($$p{'description'} ? $$p{'description'} : '&nbsp;' ), "\n";
	    print end_Tr, "\n";
	}
	print end_table, "\n";
    }
    my $args = {};
    if ( $hidesql ) {
        $args->{'hidesql'} = 1;
    }
    print Footer($args), end_html;
}

