# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Schedule;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p *i *font);

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;

use InterviewTable;

my $metaData = \%::InterviewTable;

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


sub addConverter {
    my $cvtlist = shift;
    $cvtlist->{'schedule_id'} = \&Schedule::convert;
}

sub getRecord
{
    my $id = shift;
    my @scheds = readComplexRecord({
        -table=>\%::InterviewTable,
        -column=>"id",
        -value=>$id,
    });
    if (scalar(@scheds) <= 0 ) {
        Utility::redError("readComplexRecord returnd zero schedules for #$id in schedule.cgi-doSave");
    }	
    return $scheds[0];
}

sub convert
{
    my $value = shift;
    my @recs = getRecordsMatch({-table=>\%::InterviewTable, -column=>"id", -value=>$value});
    if ( scalar @recs == 0 ) {
        return "#$value (deleted)";
    } else {
        return Schedule::link($value);
    }
}

sub link
{
    my $value = shift;
    my $url = Layout::fullURL("schedule.cgi") . "?op=view;schedule_id=$value";
    return a({-href=>$url}, $value);
}

##
## getInterviewers - return an array of user ids of people who are listed
##                   as interviewers on the given schedule
##

sub getInterviewers
{
    my $id = shift;
    my @scheds = readComplexRecord({
        -table=>\%::InterviewTable,
        -column=>"id",
        -value=>$id,
    });
    my $schedule = $scheds[0];
#Utility::ObjDump($schedule);
    my %users = ();
    foreach my $slot ( @{$schedule->{'slots'}} ) {
        foreach my $person ( @{$slot->{'persons'}} ) {
            push @{$users{$person->{'user_id'}}}, {
                'type' => $slot->{'type'},
                'date' => $schedule->{'date'},
                'time' => Schedule::convertTime($slot->{'time'}),
                'status' => $schedule->{'status'},
            };
        }
    }
#Utility::ObjDump(\%users);
    return \%users;
}

sub convertTime
{
    my ($t) = (@_);
    return sprintf("%d:%02d", int($t/60), $t%60);
}

sub getCandidatesByDate
{
    my ($time, $type) = (@_);
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($time);
    my $date = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $day_of_month);
    my @schedules = getRecordsMatch({
	-table=>\%::InterviewTable,
	-column=>"date",
	-value=>$date,
    });
    my $result = "";
    my $sep = "";
    my %people;
    my %user;
    if ( $type eq "user" ) {
	%user = makeMap(\%::UserTable,"id", "name");
    }
    
    foreach my $s ( @schedules ) {
	my @recs = getRecordsWhere({-table=>\%::CandidateTable,
				    -where=>"candidate.id = " . SQLQuote($s->{'candidate_id'}),
				    -dojoin=>"2"});
	my $rec = $recs[0];
	next if ( $rec->{'status'} eq "TEST");
	my @schedules = readComplexRecord({
	    -table=>\%::InterviewTable,
	    -column=>"id",
	    -value=>$$s{'id'},
	});
	my $sch = $schedules[0];
	my $isphone = 0;
	if ( $sch->{'purpose'} =~ /phone/i ) {
	    $isphone = 1;
	}
	if ( scalar(@{$sch->{'slots'}}) == 1 ) {
	    my $slot = $sch->{'slots'}[0];
	    if ( $slot->{'type'} eq 'PHONE' ) {
		$isphone = 1;
	    }
	}
      TYPE: {
	  $type eq "interview" and do {
#	      print Utility::ObjDump($rec);
	      $result .= "$sep" . a({-href=>"candidates.cgi?op=get;id=$s->{'candidate_id'}"},
				    $s->{'status'} eq "CANCELLED" ? i($$rec{'name'}) :
				    $$rec{'name'}) . "($$rec{'opening_id.department_id.abbrev'})" .
				    ($isphone ? img({-src=>"images/phone.gif"}) : "");
	      $sep = br() . "\n";
#	      if ( $s->{'status'} eq "CANCELLED" ) {
#		  $NumCancelled++;
#	      }
	      last TYPE;
	  };
	  $type eq "user" and do {
	      foreach my $slot ( @{$sch->{'slots'}} ) {
		  foreach my $person ( @{$slot->{'persons'}} ) {
		      if ( exists $user{$person->{'user_id'}} ) {
			  $people{$user{$person->{'user_id'}}}++;
#			  $AllUsers{$user{$person->{'user_id'}}}++;
		      } else {
			  my $user = "DELETED\#$person->{'user_id'}";
			  $people{$user}++;
#			  $AllUsers{$user}++;
		      }
		  }
	      }
	      last TYPE;
	  };
      };
    }
    if ( $type eq "user" ) {
	foreach my $pid ( sort keys %people ) {
	    $result .= "$sep" . $pid . "($people{$pid})";
	    $sep = br();
	}
    }
    return $result;
}

##
## formatSchedule - create a printable version of the schedule
##
## optional parameters:
##    showhidden ... 0 = no; 1 = yes
##    showopening ... 0 = no; 1 = yes to display the job opening text
##    showInterviewernote ... 0 = no, 1 = yes, to show the "note to interviewer"
##
## returns the printable HTML schedule

sub formatSchedule
{
    my $argv = $_[0];
    if ( ref($argv) eq "HASH" ) {
	argcvt($argv, []);
	shift;
    }
    my $result = "";
    my $schedule = shift;

    my $candidate_id = $schedule->{'candidate_id'};

    my $fullreport = ($argv && $$argv{'fullreport'}) ? 1 : 0;
    my $showinterviewernote = $$argv{'showinterviewernote'};

    my %candidate = getRecordById({
	-table=>\%::CandidateTable,
	-id=>$candidate_id,
    });

    my $tbl = \%::OpeningTable; #suppress spurious warning
    my %opening = ();
    if ( defined $candidate{'opening_id'} ) {
        %opening = getRecordById({
            -table=>\%::OpeningTable,
            -id=>$candidate{'opening_id'},
        });
    }

    $result .=  h1({-align=>"center"}, "$candidate{'name'}") . "\n";
    $result .=  p({-align=>"center"}, "Interview Schedule", br, $schedule->{'date'}) . hr . "\n";

    if ( $showinterviewernote && exists $schedule->{'note_interviewer'} && $schedule->{'note_interviewer'} ) {
	$result .=  p({-align=>"center"}, Utility::cvtTextarea($schedule->{'note_interviewer'}));
    }

    my $font_size = $fullreport ? 2 : 5;

    $result .=  start_table({-border=>"1", -cellspacing=>"0", -cellpadding=>"3", -width=>"100%"}) . "\n";

    $result .=  start_Tr;
    $result .=  td(font({-size=>$font_size}, b("Time"))) .
    td(font({-size=>$font_size}, b("Person"))) .
    td(font({-size=>$font_size}, b("Position")));


    if ( $fullreport ) {
	$result .=  td(font({-size=>$font_size}, b("Location"))) .
	td(font({-size=>$font_size}, b("Topic")));
    }

    $result .=  end_Tr;

    foreach my $slot ( sort { $a->{'time'} <=> $b->{'time'}} @{$schedule->{'slots'}} ) {
	if ( $slot->{'type'} eq $::MENU_NONE ){
	    next;
	}
	if ( !($argv && $$argv{'showhidden'}) && $slot->{'hide'}) {
	    next;
	}
	$result .=  start_Tr . "\n";
	my $start_time = Schedule::convertTime($slot->{'time'});
	my $end_time = Schedule::convertTime($slot->{'time'}+$slot->{'duration'});
	
	# Time Slot column
	$result .=  start_td({-nowrap=>"1"}) . "\n";
	$result .=  start_font({-size=>$font_size});
	$slot->{'hide'} and $result .=  start_i;
	$result .=  "$start_time-$end_time";
	if ( $slot->{'type'} ne "INTERVIEW" ) {
	    $result .=  br . $slot->{'type'};
	}
	$slot->{'hide'} and $result .=  end_i;
	$result .=  end_font . "\n";
	$result .=  end_td . "\n";
	
	# Person column
	$result .=  start_td . "\n";
	my @titles = ();
	if ( scalar @{$slot->{'persons'}} > 0) {
	    foreach my $person ( @{$slot->{'persons'}} ) {
		my %user = getRecordById({
		    -table=>\%::UserTable,
		    -id=>$person->{'user_id'},
		});
		$result .=  font({-size=>"$font_size"}, $user{'name'}) . br . "\n";
		push @titles, $user{'title'};
	    }
	} else {
	    $result .=  "&nbsp;";
	}
	$result .=  end_td;
	
	# Position column
	$result .=  start_td . "\n";
	if ( scalar @titles > 0 ) {
	    foreach my $t ( @titles ) {
		$result .=  font({-size=>$font_size}, $t) . br . "\n";
	    }
	} else {
	    $result .=  "&nbsp;";
	}
	$result .=  end_td;
	
	if ( $fullreport ) {
	    $result .=  td(font({-size=>$font_size},$slot->{'location'} ? $slot->{'location'} : "&nbsp;"));
	    $result .=  td(font({-size=>$font_size},$slot->{'topic'} ? $slot->{'topic'} : "&nbsp;"));
	}
	
	$result .=  end_Tr . "\n";
    }
    $result .=  end_table . "\n";
    
    if ( $argv && $$argv{'showopening'} && exists $opening{'url'} ) {
	$result .= displayOpeningText($opening{'url'});
    }
    return $result;
}

##
## displayOpeningText - display the contents of a job description as given by a URL
##

sub displayOpeningText
{
    my $url = shift;
    my $result = "";

    ## Get the contents of the document

    my $response = undef;
    if ( $url ) {
        $response = LWP::UserAgent->new->request(HTTP::Request->new( GET=>$url));
    }

    unless($response && $response->is_success) {
#	print p(b(font({-color=>"#ff0000"},
#		       "ERROR: Couldn't get job description $url: ", br, $response->status_line)));
        my $str = $response ? $response->status_line() : 'No document URL was provided';
        $result .= p("The job description text is currently unavailable ($str).");
	return;
    }

    ## Find the body tag and copy the contents below it to the browser

    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments('true');
    $tree->parse($response->content);
    my $body = $tree->look_down("_tag", "body");

    foreach my $content ( $body->content_list() ) {
	$result .= $content->as_HTML() if ref($content);
    }
    $tree->delete;
    return $result
}

1;
