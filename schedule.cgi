#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


# to circumvent the name clash around "Template"

BEGIN { unshift @INC, "."; }

use strict;
use CGI::Carp qw(fatalsToBrowser);

use Getopt::Std;
use CGI qw(:standard -nosticky *table *Tr *td *i *font);

use HTML::TreeBuilder;
use LWP::UserAgent;

use Application;
use Argcvt;
use Changes;
use Audit;
use Login;
use Database;
use Candidate;
use Layout;
use OptionMenuWidget;
use Utility;
use Email;
use Template;
use Schedule;

require "globals.pl";

use CandidateTable;
use UserTable;
use InterviewTable;
use OpeningTable;
use InterviewSlotTable;

Application::Init();

$::JSCRIPT = <<'EOF';
function newtimes(i)
{
    d = document.forms[0].duration;
    h = document.forms[0].hour;
    m = document.forms[0].minute;
    t = Number(h.options[h.selectedIndex].value)*60+Number(m.options[m.selectedIndex].value);
    for ( i=1 ; i<d.length ; i++ ) {
	val = Number(d[i-1].options[d[i-1].selectedIndex].value);
	t += val;
	nh = Math.floor(t/60);
	nm = t%60;
	if ( nm < 10 ) {
	    nm = "0" + nm;
	}
	document.forms[0].time[i-1].value = nh + ":" + nm;
	//		document.forms[0].debug[i].value = nh + " " + nm;
    }
}
function defocus(x) {
    if (navigator.appName == 'Microsoft Internet Explorer' || document.all)
        x.blur();
}

function settype(i)
{
    t = document.forms[0].type[i];
    if ( t.selectedIndex == 0 ) {
	for ( i=1 ; i<t.length ; t++ ) {
	    if (t.options[i].value == "INTERVIEW" ) {
		t.selectedIndex = i;
		break;
	    }
	}
    }
}

EOF

    $::NUMSLOTS = 12;

if ( defined param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "save" and do {
          doSave();
          last SWITCH;
      };
      $op eq "format" and do {
          doFormat();
          last SWITCH;
      };
      $op eq "preformat" and do {
          doPreformat();
          last SWITCH;
      };
      $op eq "view" and do {
          doView();
          last SWITCH;
      };
      $op eq "edit" and do {
          doEdit();
          last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
    doMustLogin(url(-absolute => 1, -query=>1));
    
    print header;
    ConnectToDatabase();
    
    my $candidate_id = param("candidate_id");
    if ( !defined param("candidate_id") ) {
	print start_html;
	Utility::redError("There must at least be a candidate id specified");
	print Footer({-url=>url(-absolute => 1, -query=>1)}), end_html;
	return;
    }
    
    doScheduleForm({-op=>"create",
		    -candidate_id=>$candidate_id});
    
    print end_html;
}

##
## doScheduleForm - the main for for entering and editing a schedule
##
## candidate_id ... PK of the candidate
## schedule_id ... PK of the schedule (if in edit mode)
## op ... "edit" or "create"
##
## if op eq "edit" then schedule_id must be defined, other wise candidate_id must be defined.
##

sub doScheduleForm
{
    my $argv = shift;
    argcvt($argv, ["op"], ['echedule_id', 'candidate_id']);

    my $op = $$argv{'op'};

    my ($candidate_id, $schedule_id);

    my $schedule;
    my %candidate;
    if ( defined $$argv{'schedule_id'} ) {
	$schedule_id = $$argv{'schedule_id'};
	my @scheds = readComplexRecord({
	    -table=>\%::InterviewTable,
	    -column=>"id",
	    -value=>$schedule_id,
	});
	$schedule = $scheds[0];
	$candidate_id = $$schedule{'candidate_id'};
	%candidate = getRecordById({
	    -table=>\%::CandidateTable,
	    -id=>$candidate_id,
	});
    } elsif ( defined $$argv{'candidate_id'} ) {
	$candidate_id = $$argv{'candidate_id'};
	%candidate = getRecordById({
	    -table=>\%::CandidateTable,
	    -id=>$candidate_id,
	});
    }
    
    ##
    ## From this point on, %candidate is well defined.  %schedule is or is not depending on whether
    ## this is for creating, or editing a schedule.
    ##

    my $headstr = ($op eq "edit" ? "Edit" : "Make") . " a Schedule for $candidate{'name'}";
    print doHeading({-title=>$headstr,
		     -script=>[
			       { -language => "Javascript",
				 -code => "$::JSCRIPT"
				 },
			       ],
		     -onload=>"newtimes();"}), "\n";

    print Layout::startForm({-name=>"form", -action=>url(-absolute=>1)}), "\n";

    param("op", "save");
    print hidden({-name=>"op", -default=>"save"});
    if ( defined $schedule_id ) {
	print hidden({-name=>"schedule_id", -default=>$schedule_id});
    }
    print hidden({-name=>"candidate_id", -default=>$candidate_id});
    print hidden({-name=>"slots", -default=>$::NUMSLOTS});

    print start_table({-border=>"0", -cellpadding=>"4"}), "\n";

    print start_Tr, "\n";
    ##
    ## Date
    ##
    print td({-align=>"right"}, "Date of interview:");
    print td(textfield({-name=>"date", -size=>"12", -default=>$$schedule{'date'}}),
	     a({-href=>"javascript:show_calendar('form.date');"},
	       img({-src=>"images/show_calendar.gif", -border=>"0"})),
             " YYYY-MM-DD"), "\n";
    Layout::addValidation({-table=>\%::InterviewTable,
			  -column=>"date",
		      });
			  
    print end_Tr, "\n";

    ##
    ## Purpose
    ##
    print start_Tr, "\n";
    print td({-align=>"right"}, "Purpose of interview:");
    print td(textfield({-name=>"purpose", -size=>"40", -default=>$$schedule{'purpose'}}),
	     Template::getMenu({-table=>"interview",
				-column=>"purpose",
				-control=>"purpose",
			    }),
	     ), "\n";
    Layout::addValidation({-table=>\%::InterviewTable,
			  -column=>"purpose",
		      });
    print end_Tr, "\n";

    ##
    ## Status
    ##

    print start_Tr, "\n";
    print td({-align=>"right"}, "Status:"), "\n";
    print td(PulldownMenu({-table=>\%::InterviewTable,
			   -column=>"status",
			   -default=>$$schedule{'status'}})), "\n";
    print end_Tr, "\n";

    ##
    ## Note to the interviewers - placed at the top of the internal schedule report
    ##

    print start_Tr, "\n";
    print td({-align=>"right"}, "Note to all interviewers:", br,
	     Template::getMenu({-table=>"interview",
				-column=>"note_interviewer",
				-control=>"note_interviewer",
			    }),
	     );
    print td(textarea({-name=>"note_interviewer",
		       -columns=>"80",
		       -rows=>"10",
		       -default=>$$schedule{'note_interviewer'}})), "\n";
    print end_Tr, "\n";

    print end_table, "\n";

    print checkbox({-name=>"skipemail", -label=>"Do not send email"}),br, br, "\n";
    print br(), submit({-name=>"Save Schedule"}), br, br;

    print start_table({-cellpadding=>"4", -cellspacing=>"0", -border=>"1"}), "\n";
    print Tr(
	     td(b("Hide")), "\n",
	     td(b("Time")), "\n",
	     td(b("Duration")), "\n",
	     td(b("Type")),
	     td(b("Interviewer(s)")), "\n",
	     td(b("Location")), "\n",
	     td(b("Topics")), "\n",
	     ), "\n";

    for(my $i=0 ; $i<$::NUMSLOTS ; $i++ ) {
	
	print start_Tr, "\n";
	
	# The "hide" parameters need to be explicitly named,
	# since CGI leaves the unchecked ones out of the result array completely
	
	print td({-valign=>"top"},
		 checkbox({-name=>"hide$i", -label=>""})), "\n";
	
	
	if ( $i == 0 ) {
	    my ($defaulthour, $defaultmin);
	    if ( $op eq "edit" ) {
		$defaulthour = int($schedule->{'slots'}->[0]->{'time'} / 60);
		$defaultmin =  $schedule->{'slots'}->[0]->{'time'} % 60;
	    } else {
		$defaulthour = "9";
		$defaultmin = "00";
	    }
	    print td({-valign=>"top", -nowrap=>"1"},
		     popup_menu({-name=>"hour",
				 -onChange=>"newtimes($i);",
				 -values=>[5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21],
				 -labels=>{
				     "5" => "5a",
				     "6" => "6a",
				     "7" => "7a",
				     "8" => "8a",
				     "9" => "9a",
				     "10" => "10a",
				     "11" => "11a",
				     "12" => "12p",
				     "13" => "1p",
				     "14" => "2p",
				     "15" => "3p",
				     "16" => "4p",
				     "17" => "5p",
				     "18" => "6p",
				     "19" => "7p",
				     "20" => "8p",
				     "21" => "9p",
				     },
					 -default=>$defaulthour}),":",
		     popup_menu({-name=>"minute",
				 -onChange=>"newtimes($i);",
				 -values=>[0,15,30,45],
				 -labels=>{
				     "0" => "00",
				     "15" => "15",
				     "30" => "30",
				     "45" => "45"
				     },
					 -default=>$defaultmin}));
	} else {
	    print td({-valign=>"top"},
		     textfield({-onFocus=>"defocus(this);",
				-name=>"time",
				-size=>"5",
				-style=>"color:#606060"}));
	}
	
	my $duration;
	if ( $op eq "edit" ) {
	    $duration = $schedule->{'slots'}->[$i]->{'duration'};
	} else {
	    $duration = "45";
	}
	print td({-valign=>"top"},
		 popup_menu({-name=>"duration",
			     -onChange=>"newtimes($i);",
			     -values=>[0,15,30,45,60,75,90,105,120],
			     -labels=>{
				 "0" => "skip",
				 "15" => "0:15",
				 "30" => "0:30",
				 "45" => "0:45",
				 "60" => "1:00",
				 "75" => "1:15",
				 "90" => "1:30",
				 "105" => "1:45",
				 "120" => "2:00"},
			     -default=>$duration}));
	
	##
	## Interview type (INTERVIEW, LUNCH, etc.)
	##
	my $default;
	if ( $op eq "edit" ) {
	    $default = $schedule->{'slots'}->[$i]->{'type'};
	} else {
	    $default = $::MENU_NONE;
	}
	my $tbl = \%::InterviewSlotTable; #suppress spurious warning
	print td({-valign=>"top"},
		 PulldownMenu({-table=>\%::InterviewSlotTable,
			       -column=>"type",
			       -default=>$default,
			       -null=>$::MENU_NONE}));
	
	##
	## Users
	##
	## user_id is represented as separate param names since CGI
	## doesn't seem to handle arrays of array parameters
	##
	
	my @user;
	if ( $op eq "edit" ) {
	    foreach my $person ( @{$schedule->{'slots'}->[$i]->{'persons'}} ) {
		push @user, $person->{'user_id'};
	    }
	}
	print td({-valign=>"top"},
		 OptionMenuWidget::widget({-table=>\%::UserTable,
			     -column=>"name",
                             -form=>Layout::getForm(),
			     -name=>"user_id$i",
			     -onchange=>"settype($i);",
			     -multiple=>1,
			     -default=>[@user],
			 }));
	print td({-valign=>"top"}, textfield({-name=>"location",
					      -size=>"16",
					      -default=>$schedule->{'slots'}->[$i]->{'location'}}));
	
	print td({-valign=>"top"},
		 Template::getMenu({-table=>"interview_slot",
				    -column=>"topic",
				    -control=>"topic",
				    -index=>$i,
				}),
		 textarea({-name=>"topic",
					     -rows=>"4",
					     -columns=>"40",
					     -default=>$schedule->{'slots'}->[$i]->{'topic'}}));
	
	print end_Tr;
    }

    print end_table, "\n";

    print br(), submit({-name=>"Save Schedule"});
    print Layout::endForm;
}

##
## doSave - save the schedule to the DB
##
## if the parameter schedule_id is defined, then this is a save after an edit.
##

sub doSave
{
    print header;
    ConnectToDatabase();

    my $doreplace = defined param("schedule_id");

    my $self_url = url(-absolute => 1, -query=>1);

    my $schedule_id;
    if ( $doreplace ) {
	$schedule_id = param("schedule_id");
    }
    my $candidate_id = param("candidate_id");
    my $reload = "candidates.cgi?op=get&id=$candidate_id";

    print doHeading({ -title=>"Save Schedule",
		       -head=>meta({-http_equiv=>"Refresh",-content=>"$::REFRESH;URL=$reload"})});;

    my $purpose = param("purpose");
    my $status = param("status");

    my $date = param("date");
    my $hour = param("hour");
    my $minute = param("minute");
    my @durations = param("duration");
    my @time = param("time");
    my @location = param("location");
    my @topic = param("topic");
    my @type = param("type");
    my $note_interviewer = param("note_interviewer");

    my %schedule;
    $schedule{'date'} = $date;
    $schedule{'hour'} = $hour;
    $schedule{'minute'} = $minute;
    $schedule{'purpose'} = $purpose;
    $schedule{'candidate_id'} = $candidate_id;
    $schedule{'status'} = $status;
    $schedule{'note_interviewer'} = $note_interviewer;

    my @slots = ();
    my $slot;
    my $curtime;
    for ( my $i = 0 ; $i < scalar @durations ; $i++ ) {
	if ( $type[$i] eq "$::MENU_NONE" || $type[$i] eq '0' ) {
	    next;
	}
	$slot = {};
	$slot->{'duration'} = $durations[$i];
	$slot->{'location'} = $location[$i];
	$slot->{'topic'} = $topic[$i];
	$slot->{'type'} = $type[$i];
	$slot->{'hide'} = defined param("hide$i") ? 1 : 0;
	
	my @user = param("user_id$i");
	my @persons = ();
	my $person;
	foreach my $int ( @user ) {
	    $person = {};
	    $person->{'user_id'} = $int;
	    push @persons, $person;
	}
	$slot->{'persons'} = \@persons;
	if ( $i == 0 ) {
	    $curtime = $hour*60 + $minute;
	    $slot->{'time'} = $curtime;
	} else {
	    $slot->{'time'} = $curtime;
	}
	$curtime += $durations[$i];
	push @slots, $slot;
    }
    $schedule{'slots'} = \@slots;
    
    my $debug = 0;
    if ( scalar @slots > 0 ) {

	my $new_schedule_id = $schedule_id;
	
	my $junk = Converter::getConverterRef(); #suppress spurious warning
	my $changes = new Changes(Converter::getConverterRef());
	
	if ( $doreplace ) {
	    
	    ##
	    ## Determine how much of the schedule record changed
	    ##   if it is only the header, then we will UPDATE the schedule table.
	    ##   otherwise we rewrite a new copy of the entire schedule and delete the old one
	    ##
	    
	    my @scheds = readComplexRecord({
		-table=>\%::InterviewTable,
		-column=>"id",
		-value=>$schedule_id,
	    });
	    if (scalar(@scheds) <= 0 ) {
		Utility::redError("readComplexRecord returnd zero schedules for #$schedule_id in schedule.cgi-doSave");
		}	
	    my $oldschedule = $scheds[0];
	    my $match = 1;
	  CHECK:{
	      
	      ## Check that the number of interview slots is the same
	      
	      if ( scalar @{$schedule{'slots'}} != scalar @{$$oldschedule{'slots'}} ) {
		  $debug and print p("Number of slots mismatch.", scalar @{$schedule{'slots'}}, scalar @{$$oldschedule{'slots'}});
		  $match = 0;
		  last CHECK;
	      }
	      
	      ## number of slots matches, check that each slot is identical
	      
	      for ( my $i=0 ; $i<scalar @{$schedule{'slots'}} ; $i++ ) {
		  my $old = $oldschedule->{'slots'}->[$i];
		  my $new = $schedule{'slots'}->[$i];
		  if ( $old->{'time'} != $new->{'time'} ||
		       $old->{'duration'} != $new->{'duration'} ||
		       $old->{'location'} ne $new->{'location'} ||
		       $old->{'topic'} ne $new->{'topic'} ||
		       $old->{'type'} ne $new->{'type'} ||
		       $old->{'hide'} != $new->{'hide'} ) {
		      $debug and print p("Slot $i content mismatch");
		      $match = 0;
		      last CHECK;
		  }
		  if ( scalar @{$old->{'persons'}} != scalar @{$new->{'persons'}} ) {
		      $debug and print p("Slot $i number of interviewers mismatch.", @{$old->{'persons'}}, scalar @{$new->{'persons'}});
		      $match = 0;
		      last CHECK;
		  }
		  for ( my $p=0 ; $p<scalar @{$old->{'persons'}} ; $p++ ) {
		      if ( $old->{'persons'}->[$p]->{'user_id'} != $new->{'persons'}->[$p]->{'user_id'} ) {
			  $debug and print p("Slot $i number interviewer list mismatch.", $old->{'persons'}->[$p]->{'user_id'}, $new->{'persons'}->[$p]->{'user_id'});
			  $match = 0;
			  last CHECK;
		      }
		  }
	      }
	  };
	    
	    ##
	    ## If the schedule slots (new and old) match exactly, update only the header
	    ## otherwise rewrite the entire record
	    ##
	    
	    if ( $match ) {
		print p("Header only changed - updating.");
		param("pk", $schedule_id);
		doUpdateFromParams({-table=>\%::InterviewTable,
				    -record=>$oldschedule,
				    -changes=>$changes});
		$changes->updateAll({-join_table=>"candidate", -join_id=>$candidate_id});
		auditUpdate($changes);
		print $changes->listHTML();
		$new_schedule_id = $schedule_id;
	    } else {
		deleteComplexRecord({
		    -table=>\%::InterviewTable,
		    -column=>"id",
		    -value=>$schedule_id,
		});
		print p("Old schedule deleted.");
		$new_schedule_id = 	writeComplexRecord({
		    -table=>\%::InterviewTable,
		    -record=>\%schedule});
		print p("New schedule saved.");
		
		$changes->add({-table=>"candidate",
			       -row=>"$candidate_id",
			       -column=>"schedule",
			       -type=>"CHANGE",
			       -old=>"$schedule_id",
			       -new=>"$new_schedule_id",
			       -user=>getLoginId()});
		auditUpdate($changes);
		print $changes->listHTML();
	    }
	} else { # not $doreplace
	    
	    $new_schedule_id = writeComplexRecord({
		-table=>\%::InterviewTable,
		-record=>\%schedule
		});
	    print p("New schedule saved.");
	    
	    $changes->add({-table=>"candidate",
			   -row=>"$candidate_id",
			   -column=>"schedule",
			   -type=>"ADD",
			   -new=>"$new_schedule_id",
			   -user=>getLoginId()});
	    auditUpdate($changes);
	    print $changes->listHTML();
	}

	## Generate an email

	my $skipemail = param("skipemail");
	if ( !(defined $skipemail && $skipemail) ) {

	    my $candidate = Candidate::getRecord($candidate_id);
	    my @mailrecips = Candidate::mailRecipients({-candidate=>$candidate});
	    my $interviewers = Schedule::getInterviewers($new_schedule_id);
	    my %dedupe;
	    foreach my $u ( @mailrecips ) {
		$dedupe{$u->{'id'}} = 1;
	    }
	    foreach my $k ( keys %$interviewers ) {
		if ( !exists $dedupe{$k} ) {
		    push @mailrecips, User::getRecord($k);
		    $dedupe{$k} = 1;
		}
	    }
	    if ( scalar(@mailrecips) > 0 ) {
		foreach my $user ( @mailrecips ) {
		    if ( $user->{'sendmail'} eq 'Y' ) {
			my $note;
			if ( $$candidate{'owner_id'} eq $user->{'id'} ) {
			    $note = "Schedule changes have been made to a candidate owned by you: " .
				candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
			} else {
			    $note = "Schedule changes have been made to a candidate that has you as a CC or an interviewer: " .
				candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
			}
			$note .= p("See schedule number " . Schedule::link($new_schedule_id));
			$note .= Schedule::formatSchedule({
			    -showhidden=>1,
			    -showopening=>0,
			    -fullreport=>1,
			    -showinterviewernote=>1,
			}, Schedule::getRecord($new_schedule_id));
			sendEmail({
    # leave this out:	-changes=>$changes,
			    -candidate=>$candidate,
			    -owner=>$user,
			    -note=>$note,
			    -commenter=>getLoginName(),
			});
			print p("Changes e-mailed to $user->{'name'} at $user->{'email'}");
		    }
		}
	    } else {
		print p("No owner or CC for this candidate, no one to e-mail the changes to!");
	    }
	} else {
	    print p("Skip email checked, sending no emails");
	}

    } else {
	print p("Empty schedule - not saving.");
    }
    
    print p(a({-href=>$reload}, "Returning to candidate page..."));
    
    print Footer({-url=>"$self_url"}), end_html, "\n";
    
}


sub doFormat
{
    print header;
    ConnectToDatabase();


    print start_html;

    my $showhidden;
    my $showopening;
    my $fullreport;
    my $showinterviewernote;
    if ( defined param("type") && param("type") eq "candidate" ) {
	$showhidden = 0;
	$showopening = 1;
	$fullreport = 0;
	$showinterviewernote = 0;
    } elsif ( defined param("type") && param("type") eq "interviewer" ) {
	$showhidden = 1;
	$showopening = 1;
	$fullreport = 1;
	$showinterviewernote = 1;
    }
    defined param("showhidden") and $showhidden = 1;
    defined param("showopening") and $showopening = 1;
    defined param("fullreport") and $fullreport = 1;

    my $schedule_id = param("schedule_id");

    my @schedules = readComplexRecord({
	-table=>\%::InterviewTable,
	-column=>"id",
	-value=>$schedule_id,
    });

    if( scalar(@schedules) == 0 ) {
	print p("Sorry, this schedule is no longer in the system!");
    } else {
#	print Utility::ObjDump($schedules[0]);
	print Schedule::formatSchedule({-showhidden=>$showhidden,
			-showopening=>$showopening,
			-fullreport=>$fullreport,
			-showinterviewernote=>$showinterviewernote,
		    }, $schedules[0]);
    }
    print end_html;
}


sub doPreformat
{
    my $q = new CGI;
    $q->param("op", "format");
    $q->delete("Format");
    print $q->redirect(-location=>$q->url(-absolute => 1, -query=>1), -method=>"get");
}


sub doView
{
    if ( defined param("showhidden") &&
	 defined param("showopening") &&
	 defined param("fullreport") ) {
	doPreformat();
	return;
    }

    print header;
    print start_html;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $schedule_id = param("schedule_id");

  BODY: {
      if ( !getRecordById({
	  -table=>\%::InterviewTable,
	  -id=>$schedule_id})) {
	  print p("Sorry, this schedule is no longer stored in the system.");
	  last BODY;
      };
      
      print Layout::startForm;
      
      param("op", "preformat");
      print hidden({-name=>"op", -default=>"format"});
      print hidden({-name=>"schedule_id", -default=>"$schedule_id"});
      
      print h1("Format a Schedule"), hr;
      print checkbox({-name=>"showhidden", -label=>"Show hidden interviews", -checked=>1}), "\n";
      print checkbox({-name=>"showopening", -label=>"Show job opening text on schedule", -checked=>1}), "\n";
      print checkbox({-name=>"fullreport", -label=>"Full schedule report", -checked=>1}), "\n";
      
      print br, submit({-name=>"Format"});
      print Layout::endForm;
  };	  
    print Footer({-url=>"$self_url"}), end_html;
}


##
## doEdit - process the "edit schedule" URL
##

sub doEdit
{
    doMustLogin(url(-absolute => 1, -query=>1));

    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $schedule_id = param("schedule_id");

    doScheduleForm({-op=>"edit",
		    -schedule_id=>$schedule_id});

    print start_html;

    print Footer({-url=>"$self_url"}), end_html;
}
