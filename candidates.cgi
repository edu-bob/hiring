#!/usr/bin/perl -w
# Copyright(c) 2003-2021 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


# to circumvent the name clash around "Template"

BEGIN { unshift @INC, "."; }

##
## candidates.cgi 
##
## This responds to all of the various requests for candidate-related pages.
##
## Which function to perform is controlled by the "op" paramater.
##

use Getopt::Std;
use CGI qw(:standard -nosticky *table *Tr *td *p *ul *blockquote, *div);
use CGI::Carp qw(fatalsToBrowser);
use Mail::Mailer;
use File::Path;

use Changes;
use Login;
use Email;

require "globals.pl";
use Document;
use Audit;
use Database;
use Layout;
use Argcvt;
use Utility;
use Candidate;
use User;
use Application;
use Cc;
use Template;
use OpeningCc;
use OpeningAction;
use OpeningEvaluation;

use CandidateTable;
use CommentTable;
use UserTable;
use DocumentTable;
use InterviewTable;
use ActionTable;
use OpeningTable;
use ParamTable;
use TempDirTable;
use RatingTable;

Application::Init();

# In must-log-in mode, make sure we're logged in

my $mustLogIn = Param::getValueByName('must-log-in');
if ( $mustLogIn && ref $mustLogIn ) {
    $mustLogIn = $mustLogIn->{'value'};
}
if ( $mustLogIn && !isLoggedIn() ) {
    doMustLogin(url(-absolute => 1, -query=>1));;
}


if ( defined param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "audit" and do {
	  doAudit();
	  last SWITCH;
      };
      $op eq "test" and do {
	  doTest();
	  last SWITCH;
      };
      $op eq "add" and do {
	  doAdd();
	  last SWITCH;
      };
      $op eq "addfinish" and do {
          doAddFinish();
	  last SWITCH;
      };
      $op eq "edit" and do {
	  doEdit();
	  last SWITCH;
      };
      $op eq "editfinish" and do {
	  doEditFinish();
	  last SWITCH;
      };
      $op eq "editdelete" and do {
	  doEditDelete();
	  last SWITCH;
      };
      $op eq "get" and do {
	  doGet();
	  last SWITCH;
      };
      $op eq "upload" and do {
	  doUpload();
	  last SWITCH;
      };
      $op eq "uploadfinish" and do {
	  doUploadFinish();
	  last SWITCH;
      };
      $op eq "addcomment" and do {
	  doAddComment();
	  last SWITCH;
      };
      $op eq "addrating" and do {
	  doAddRating();
	  last SWITCH;
      };
      $op eq "addstufffinish" and do {
	  doAddStuffFinish();
	  last SWITCH;
      };
      $op eq "viewcomment" and do {
	  doViewComment();
	  last SWITCH;
      };
      $op eq "viewallcomments" and do {
	  doViewAllComments();
	  last SWITCH;
      };
      $op eq "editcomment" and do {
	  doEditComment();
	  last SWITCH;
      };
      $op eq "editcommentfinish" and do {
	  doEditCommentFinish();
	  last SWITCH;
      };
      $op eq "reject" and do {
	  doReject();
	  last SWITCH;
      };
      $op eq "dump" and do {
	  doDump();
	  last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

##
## doFirstPage - this is normally done by manage.cgi
##

sub doFirstPage
{
    print header;
    ConnectToDatabase();

    my $self_url = self_url;
    print doHeading({-title=>"Add a Candidate"});

    param("op", "addfinish");
    print Layout::startForm({-action=>url(-absolute=>1)}), "\n";
    print hidden({-name=>"op", -default=>"addfinish"}), "\n";
    print doEntryForm({-table=>\%::CandidateTable});
    print submit({-name=>"Add"});
    print Layout::endForm;

    print h2("Edit/Delete Candidates"), hr, "\n";
    print Layout::startForm({-action=>url(-absolute=>1)});
    print doEditTable({-table=>\%::CandidateTable});
    print Layout::endForm;

    print Footer({-url=>"$self_url"}), end_html, "\n";
}

##
## doAdd - process the "Add a Candidate" POST or GET
##

sub doAdd
{
    doMustLogin(url(-absolute => 1, -query=>1));

    print header;
    ConnectToDatabase();

    my $self_url = self_url;

## Generate the mapping of opening to CC list as JavaScript
## and add that to the head section.

    my $ccjs = OpeningCc::generateCCJavaScript();
    my $actionjs = OpeningAction::generateActionJavaScript();
    print doHeading({-title=>"Add a Candidate",
		     -script=>[
			  {
			      -language=>'JavaScript1.2',
			      -src=>'javascript/addcandidate.js',
			  },
			  {
			      -language=>'JavaScript1.2',
			      -code =>$ccjs,
			  },
			  {
			      -language=>'JavaScript1.2',
			      -code =>$actionjs,
			  },
			 ],
		    });

    ## set up the default values

    my $record;
    $$record{'owner_id'} = Login::getLoginId();

    print p("Enter as much information as you can about this candidate.\n Optionally, add up to two documents to attach to the candidate's record and add one block of comments at the same time.");

    param("op", "addfinish");
    param("pass", 1);
    print Layout::startForm({
	-action=>url(-absolute=>1),
	-enctype=>'multipart/form-data',
	-status=>1}),
    hidden({-name=>"op", -default=>"addfinish"}), "\n",
    hidden({-name=>"pass", -default=>"1"}), "\n", "\n";
    print doEntryForm({
	-table=>\%::CandidateTable,
	    -record=>$record,
	    -back=>$self_url,
	    -clientonchange=>{
		'opening_id' => 'setCCList(this);setActionList(this);' # XXX RLB
	},
    });

    ## Add a couple of document upload fields
    ## The tables inside tables are to get the tab order right

    print h3("Upload Documents for this Candidate"), "\n";
    print start_table({-border=>"0"}), "\n";
    print Tr(
	     td({-align=>"center", -colspan=>"1"}, b("First Upload File")),
	     td({-width=>"16"}, "&nbsp;"),
	     td({-align=>"center", -colspan=>"1"}, b("Second Upload File")),
	     ), "\n";
    print start_Tr, "\n";
    print start_td, "\n";
    my $onchange = Layout::statusCheckOnChange({-default=>""});
    print table({-border=>"0"},
                Tr(
                   td({-align=>"right"},"File:"),
                   td(filefield({-name=>"filename0", -size=>"30", -onchange=>$onchange})),
                   ),
                Tr(
                   td({-align=>"right"},"Description:"),
                   td(textfield({-name=>"contents0", -size=>"30", -default=>"resume", -onchange=>$onchange})),
                   ),
                ), "\n";
    print end_td, "\n";
    print td({-width=>"16"}, "&nbsp;"), "\n";
    print start_td, "\n";
    print table({-border=>"0"},
                Tr(
                   td({-align=>"right"},"File:"),
                   td(filefield({-name=>"filename1", -size=>"30", -onchange=>$onchange})),
                   ),
                Tr(
                   td({-align=>"right"},"Description:"),
                   td(textfield({-name=>"contents1", -size=>"30", -onchange=>$onchange})),
                   ),
                ), "\n";
    print end_td, "\n";
    print end_Tr, "\n";

    print end_table, "\n";

    print h3("Add a Comment for this Candidate");
    print table(
		Tr(
		   td({-align=>"right"},"Comments:"),
		   td(textarea({
		       -name=>"comment",
		       -rows=>"12",
		       -columns=>"80",
		       -onchange=>$onchange}))
		   ),
		);
    print hr, "\n";
    print "Optional top paragraph for the outgoing email about changes (plain text): ", br, textarea({-name=>"msg", -columns=>80, -rows=>3}), br, br, "\n";
    print checkbox({-name=>"skipemail", -label=>"Do not send email"}),br, br, "\n";

    print submit({-name=>"Add"});
    print Layout::endForm;

    print Footer({-url=>"$self_url"}), end_html;
}

##
## doAddFinish - process the POST from adding a candidate
##
## There may be a comment added - if so, update the comment table.
## There may be one or more files listed - if so, save them.
##

sub doAddFinish
{
    my $insert_id;
    my $url = url(-absolute=>1);
    my $self_url = url(-absolute => 1, -query=>1);

    print header;
    ConnectToDatabase();

    print doHeading({-title=>"Add a Candidate",
		     -noheading=>1});

    my $errors = 0;


  BODY: {
      my $skipemail = param("skipemail");
      my $name = param("name");
      if ( $name =~ /^\s*$/ ) {
	  print p(b("Not adding an empty name - skipping"));
	  last BODY;
      }

      ##
      ## The tricky part of this is that there may be one or two files to upload.
      ## The only chance to upload them is on the first POST. so even if the user
      ## decides to NOT add this entry to the database because, perhaps,
      ## it is already there, we still need to upload the files right now
      ## and save them for later use.
      ##

      my $bytes = 0;
      my $filesuploaded = 0;
      if ( param("pass") == 1 ) {
	  param("local", "1");

          ##
          ## New candidate processing, pass one.
          ##
          ## this is the only chance to upload the files.
          ## Do that now and allocate the entries in the document table
          ## for them.  If there are duplicate names detected, these can
          ## be subsequently removed from that table.
          ##
          ## If there are duplicates, pass the PKs of these uploaded files
          ## as form data named
          ##     filepk1 ... pk of the first uploaded file
          ##     filepk2 ... pk of the second uploaded file
          ##

        FILE:
	  for ( my $i=0 ; $i<2 ; $i++ ) {
	      my $parentdir;
	      if ( defined param("filename$i") && notblank(param("filename$i"))  ) {

		  my ($uploadbytes, $pk) = doUploadFile({-fileparam=>"filename$i",
                                                         -contentparam=>"contents$i",
                                                         -tmp=>1});
                  if ( $uploadbytes == 0 ) {
                      $errors++;
                      print Utility::errorMessage(param("filename$i"), " does not exist or is empty");
                      next FILE;
                  }

		  param("filepk$i", $pk);
#		  $uploadbytes > 0 && $filesuploaded++;
		  $bytes += $uploadbytes;
	      }
	  }

	  ##
	  ## Check if the name is already in the database.
	  ##

	  my %matchnames = getNameMatches($name);
	  if ( scalar(keys %matchnames) > 0 ) {
	      print h1(font({-color=>"#ff0000"}, "Attention!")), hr;

	      print p("There may be duplicates to ", b($name), " in the database.");
	      print start_ul;
	      foreach my $k ( sort {$b<=>$a} keys %matchnames ) {
		  print li("Words matched: $k");
		  print start_ul;
		  foreach my $e ( @{$matchnames{$k}} ) {
		      my $candidate = Candidate::getRecord($e->{'id'});
		      print li(candidateLink({-id=>$e->{'id'},
					      -name=>$e->{'name'}}),
			       " (#$e->{'id'}) created $candidate->{'creation'} - $candidate->{'status'}");
		  }
		  print end_ul;
	      }
	      print end_ul;
	      print Layout::startForm, "\n";
	      param("pass", 2);
	      foreach my $p ( param() ) {
		  my @v = param($p);
		  print hidden({-name=>$p, -default=>"$v[0]"}), "\n";
	      }
	      print p("Either continue or go back or start over.");
	      print submit({-name=>"Continue"});
	      print Layout::endForm, "\n";
	      last BODY;
	  } else {
	      param("pass", 2);
	  }
	  ## If there were no name matches, this falls through to the next pass code
      }

      ##
      ## PASS 2 - process adding the candidate
      ##
      ## The files have already been uploaded and added to the document table
      ## and need to be marked as not temporary and also attached to a candidate.
      ##
      ## First, scrape out the candidate entries from the form data and
      ## update the candidate table.
      ##

      if ( param("pass") == 2 ) {
	  my $changes = new Changes(Converter::getConverterRef());
	  my $candidate_id = doInsertFromParams({-table=>\%::CandidateTable,
						 -changes=>$changes});

	  ##
	  ## Update the uploaded files.  They were uploaded on pass one and are
          ## dangling in the document table.
	  ##

	  for ( my $i = 0 ; $i<2 ; $i++ ) {
	      if ( defined param("filepk$i") ) {
		  my $pk = param("filepk$i");

                  my $record = {
                      'id' => $pk,
                      'candidate_id' => $candidate_id,
                      'temporary' => undef,
                  };
                  my $old = {
                      'id' => $pk,
                  };
                  updateSimpleRecord({
                      -table=>\%::DocumentTable,
                      -new=>$record,
                      -old=>$old,
                      -donulls=>1,
                  });

		  $filesuploaded++;
		  $changes && $changes->add({-table=>"candidate",
					     -row=>$candidate_id,
					     -column=>"document",
					     -type=>"ADD",
					     -new=>"$pk",
					     -user=>getLoginId(),
					 });
	      }
	  }

	  ##
	  ## If there is also comment text added,
          ## then update the comment table as well
	  ##

	  my $comment = param("comment");
	  my $comment_id;
	  if ( defined $comment && length($comment) > 0 && $comment !~ /^[\s\n]*$/ ) {
	      param("candidate_id", $candidate_id);
	      param("user_id", getLoginId());
	      $comment_id = doInsertFromParams({-table=>\%::CommentTable,
						-changes=>$changes,
						-join_table=>"candidate",
						-join_id=>$candidate_id,
					    });
	      $changes->add({-table=>"candidate",
			     -row=>$candidate_id,
			     -column=>"comment",
			     -type=>"ADD",
			     -new=>$comment_id,
			     -user=>getLoginId()});
	  } else {
	      $comment = undef; #in case it's all whitespace
	  }

	  ##
	  ## If there is an optional email message paragraph, add it
	  ##
	  my $message = param("msg");

	  ##
	  ## Report on any changes that were made.
	  ##

	  if ( $changes->size() > 0 ) {
	      auditUpdate($changes);
	      print start_p;
	      print "Candidate $candidate_id added.", br;
	      if ( $comment ) {
		  print "A comment was added.", br;
	      }
	      if ( $filesuploaded && $filesuploaded > 0 ) {
		  print "$filesuploaded document", ($filesuploaded>1?"s were":" was"), " uploaded.";
	      }
	      print end_p;
	      print $changes->listHTML({-user=>Login::getLoginRec()});

	      ## email the new entry to the owner

	      my $candidate = Candidate::getRecord($candidate_id);
	      my @mailrecips = Candidate::mailRecipients({-candidate=>$candidate});
	      if ( !(defined $skipemail && $skipemail) ) {
		  if ( scalar(@mailrecips) > 0 ) {
		      foreach my $user ( @mailrecips ) {
			  my $note;
			  if ( $candidate->{'owner_id'} eq $user->{'id'} ) {
			      $note = "This candidate, " .
				  candidateLink({-name=>$candidate->{'name'}, -id=>$candidate->{'id'}}) .
				  ", has been added and assigned to you.";
			  } else {
			      $note = "This candidate, " .
				  candidateLink({-name=>$candidate->{'name'}, -id=>$candidate->{'id'}}) .
				  ", has been added and you are on the CC list.";
			  }
			  print p("Sending to $$user{'name'} via $$user{'email'}");
			  my $sent = sendEmail({-changes=>$changes,
						-candidate=>$candidate,
						-owner=>$user,
						-comment=>$comment,
						-commenter=>getLoginName(),
						-note=>$note,,
						-showskips => 1,  ## This does NOT override 'seesalary'
						-message => $message,
				 });
			  if ( !$sent ) {
			      print p("CORRECTION: Nothing sent to $user->{'name'} at $user->{'email'}");
			  }
		      }
		  } else {
		      print p("No owner, no CCs, for this candidate, no one to e-mail the changes to!");
		  }
	      } else {
		  print p("Skip email selected; not sending any email about this change.");
	      }
	  }

	  print p(a({-href=>"$url?op=get&id=$candidate_id"}, "View $name"));
      }

  };

    print p(a({-href=>"$url?op=add"}, "Start over: Add another new candidate"));
    print Footer({-url=>"$self_url"}), end_html, "\n";
}



# obsolete

sub doEditDelete
{
    print header;
    ConnectToDatabase();

    my @params = param();
    foreach my $p ( @params ) {
      SWITCH:
	{
	    $p =~ /^edit[0-9]+/ and do {
		$p =~ s/^edit//;
		doEditInternal($p);
		last SWITCH;
	    };
	    $p =~ /^delete[0-9]+/ and do {
		$p =~ s/^delete//;
		doDelete($p);
		last SWITCH;
	    };
	};
    }
}


sub doEdit
{
    doMustLogin(url(-absolute => 1, -query=>1));

    print header;
    ConnectToDatabase();

    my $id = param("id");
    doEditInternal($id);
}


sub doEditInternal
{
    my $self_url = url(-absolute => 1, -query=>1);
    my $pk = shift;
    my $candidate = Candidate::getRecord($pk);

    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }

    print doHeading({-title=>"Edit Candidate $$candidate{'name'}"});

  BODY: {
#	  print Utility::ObjDump(\%candidate);
      param("op", "editfinish");
      print Layout::startForm({-action=>url(-absolute=>1), -status=>1}), "\n";
      print hidden({-name=>"op", -default=>"editfinish"}), "\n";
      print submit({-name=>"Update"});
      param("id", "$pk");
      print hidden({-name=>"id", -default=>"$pk"});
      print doEditForm({
	  -table=>\%::CandidateTable,
	  -record=>$candidate,
	  -back=>$self_url,
#          -debug=>1,
      });

      ##
      ## for convenience, add a comment entry field here
      ##

      print h3("Add a Comment for this Candidate:");
      my $links = OpeningEvaluation::getInsertLinks(Layout::getForm(),$candidate->{'opening_id'}, 'comment');
      print $links;
      print table(
		  Tr(
		     td({-align=>"right", -width=>"20%"},
			"Comments:",
			br,
			Template::getMenu({-table=>"comment",
					   -column=>"comment",
					   -control=>"comment",
			    }),
			br,
			font({-size=>"1"}, "
Use this to add a comment at the same time as editing the candidate's record")),
		     td(textarea({-name=>"comment", -rows=>"12", -columns=>"80"}))
		     ),
		  );

      ##
      ## List of attached comments with "Delete" checkboxes
      ##
      print h3("Remove Comments");
      my @coms = getRecordsMatch({
	  -table=>\%::CommentTable,
	      -column=>"candidate_id",
	      -value=>$pk,
				 });
      if ( scalar @coms == 0 ) {
	  print p("None.");
      } else {
	  print start_table({-cellpadding=>"4"});
          print Tr(
                   td(b("Delete")),
                   td(b("Created")),
                   td(b("Comment")),
                   );
          foreach my $c ( @coms ) {
	      print Tr(
		       td(checkbox({-name=>"del_comment_$c->{'id'}", -label=>""})),
		       td($c->{'creation'}),
		       td(Comment::convert_comment($c->{'comment'}, 80)),
		       );
	  }
	  print end_table;
      }
	      
      ##
      ## List of attached documents with "Delete" checkboxes
      ##

      print h3("Remove Attached Documents");
      my @docs = getRecordsMatch({
	  -table=>\%::DocumentTable,
	  -column=>"candidate_id",
	  -value=>$pk,
      });
      if ( scalar @docs == 0 ) {
	  print p("None.");
      } else {
	  print start_table({-cellpadding=>"4"});
	  print Tr(
		   td(b("Delete")),
		   td(b("Created")),
		   td(b("Contents")),
		   td(b("Filename")),
		   );
	  foreach my $d ( @docs ) {
	      print Tr(
		       td(checkbox({-name=>"delete$d->{'id'}", -label=>""})),
		       td($d->{'creation'}),
		       td($d->{'contents'}),
		       td(Document::link({
                           -id=>$d->{'id'},
                           -name=>$d->{'filename'},
                       })),
		       );
	  }
	  print end_table;
      }

      print h3("Remove Schedules");
      my @schedules = getRecordsMatch({
	  -table=>\%::InterviewTable,
	  -column=>"candidate_id",
	  -value=>$pk
	  });
      if ( scalar @schedules == 0 ) {
	  print p("None.");
      } else {
	  print start_table({-cellpadding=>"4"});
	  print Tr(
		   td(b("Delete")),
		   td(b("When")),
		   td(b("Status")),
		   td(b("Description")),
		   );
	  foreach my $s ( @schedules ) {
	      print Tr(
		       td(checkbox({-name=>"deleteschedule$s->{'id'}", -label=>""})),
		       td($s->{'date'}),
		       td($s->{'status'}),
		       td($s->{'purpose'}),
		       );
	  }
	  print end_table;
      }

      ## Allow editing of ratings

      print hr(), "\n";
      my @ratings;
      if ( isAdmin() ) {
	  @ratings = getRecordsMatch({
	      -table=>\%::RatingTable,
	      -column=>"candidate_id",
	      -value=>$pk,
	  });
      } else {
	  my $me = getLoginId();
	  @ratings = getRecordsMatch({
	      -table=>\%::RatingTable,
	      -column=>["candidate_id","user_id"],
	      -value=>[$pk,$me],
	  });
      }

      print h3("Edit/Delete Ratings"), "\n";
      if ( scalar(@ratings) > 0 ) {
	  print start_table({-cellpadding=>"4"});
	  print start_Tr;
	  print td(b("Delete"));
	  print td(b("When")), "\n";
	  if ( isAdmin() ) {
	      print td(b("By")), "\n";
	  }
	  print td(b("Rating")), "\n";
	  print td(b("Short Comment")), "\n";
	  print end_Tr;

	  foreach my $c ( @ratings ) {
	      print start_Tr, "\n";
	      print td(checkbox({-name=>"del_rating_$c->{'id'}", -label=>""})), "\n";
	      print td($c->{'creation'}), "\n";
	      if ( isAdmin() ) {
		  print td(User::getName($c->{user_id})), "\n";
	      }
	      print td(Layout::doSingleFormElement({-table=>\%::RatingTable,
						    -column=>"rating",
						    -suffix=>"_$c->{'id'}",
						    -record=>{'rating' => $c->{'rating'}},
						})), "\n";
	      print td(textfield({-name=>"comment_$c->{'id'}", -default=>$c->{'comment'}, -size=>60})), "\n";
	      print end_Tr, "\n";
	  }
	  print end_table, "\n";
      } else {
	  print p("None."), "\n";
      }

      print hr, "\n";
      print "Optional top paragraph for the outgoing email about changes (plain text): ", br, textarea({-name=>"msg", -columns=>80, -rows=>3}), br, br, "\n";
      print checkbox({-name=>"skipemail", -label=>"Do not send email"}),br, br, "\n";
      print submit({-name=>"Update"});
      print Layout::endForm;
  };
    print Footer({-url=>"$self_url"}), end_html, "\n";
}

##
## doEditFinish (op=editfinish)
##
## Process the POST after editing a candidate record
##

sub doEditFinish
{
    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $candidate_id = param("id");
    my $candidate = Candidate::getRecord($candidate_id);
    my $changes;

    my $url = url(-absolute=>1);
    my $reload = "$url?op=get&id=$candidate_id";
    print doHeading({ -title=>"Finish Edit $$candidate{'name'}",
		      -head=>meta({-http_equiv=>"Refresh",
#                                   -content=>"300;URL=$reload"}
                                   -content=>"$::REFRESH;URL=$reload"}
                                  )});

## Track changes in this section with a "changes" record

## and later update the audit log with it

    my $newcandidate = {};
    my $comment;

    ## Get the optional message to put on the emails

    my $msg = param("msg");
    my $skipemail = param("skipemail");
  BODY: {

      $changes = new Changes(Converter::getConverterRef());
      doUpdateFromParams({
          -table=>\%::CandidateTable,
          -record=>$candidate,
          -changes=>$changes,
          -new=>$newcandidate,
#          -debug=>1,
      });
#      Utility::ObjDump($changes);
      ##
      ## If there is also comment text added, then update the comment table as well
      ##

      $comment = param("comment");
      my $comment_id;
      if ( defined $comment && length($comment) > 0 && $comment !~ /^[\s\n]*$/ ) {
	  param("candidate_id", $candidate_id);
	  param("user_id", getLoginId());
	  $comment_id = doInsertFromParams({-table=>\%::CommentTable});
	  $changes->add({-table=>"candidate",
			 -row=>$candidate_id,
			 -column=>"comment",
			 -type=>"ADD",
			 -new=>$comment_id,
			 -user=>getLoginId()});
      } else {
	  $comment = undef; #in case it's all whitespace
      }


      ## Process simple delete checkboxes in the various lists

      my @params = param();
      foreach my $p ( @params ) {
	  if ( $p =~ /del_comment_([0-9]+)/ ) {
	      my $id = $1;
	      my $query = "DELETE FROM comment WHERE id = " . SQLQuote($id);
	      SQLSend($query);
	      $changes->add({-table=>"candidate",
			     -column=>"comment",
			     -row=>$candidate_id,
			     -type=>"REMOVE",
			     -old=>$id,
			     -user=>getLoginId(),
			 });
	  }
	  if ( $p =~ /^delete([0-9]+)/ ) {
	      my $id = $1;
	      my $query = "DELETE FROM document WHERE id = " . SQLQuote($id);
	      SQLSend($query);

	      ## Update the changes object - REMOVE a document item

	      $changes->add({-table=>"candidate",
			     -column=>"document",
			     -row=>$candidate_id,
			     -type=>"REMOVE",
			     -old=>$id,
			     -user=>getLoginId(),
			 });

	  }
	  if ( $p =~ /^deleteschedule([0-9]+)/ ) {
	      my $id = $1;
	      my %schedule = getRecordById({
		  -table=>\%::InterviewTable,
		  -id=>$id,
	      });

	      deleteComplexRecord({
		  -table=>\%::InterviewTable,
		  -column=>"id",
		  -value=>$id,
	      });
	      my $old = $id;
#	      my $old = $schedule{'purpose'} ? $schedule{'purpose'} : $schedule{'date'};
	
	      ## Update the changes object - REMOVE a schedule item

	      $changes->add({-table=>"candidate",
			     -row=>$candidate_id,
			     -column=>"schedule",
			     -type=>"REMOVE",
			     -old=>"$old",
			     -user=>getLoginId(),
			 });
	  }
      }

      ##
      ## Process rating changes
      ##
      ## Rating parameters are
      ##    rating_%d ... rating value for PK %d
      ##    comment_%d ... comment for rating PK %d
      ##    del_rating_%d ... if checked, delete comment PK %d
      ##

      my %deletedrating;
      foreach my $p ( @params ) {
	  if ( $p =~ /^del_rating_([0-9]+)/ ) {
	      my $id = $1;
	      my $str = Rating::convert_candidate($id);
	      $deletedrating{$id} = 1;
	      deleteSimpleRecord({-table=>\%::RatingTable, -record=>{'id'=>$id}});
	      Rating::invalidate($id);
	      print p("Deleted rating #$id");
	      $changes->add({-table=>"candidate",
			     -row=>$candidate_id,
			     -column=>"rating",
			     -type=>"REMOVE",
			     -old=>$str,
			     -user=>getLoginId(),
			 });
# what is needed here is a remove function for each column
#	      $changes->add({-table=>\%::RatingTable,
#			     -row=>$id,
#			     -type=>"REMOVE",
#			     -user=>Login::getLoginId(),
#			     -old=>$id,
#			     -join_table=>"candidate",
#			     -join_id=>$candidate_id,
#			 });
	  }
      }
      foreach my $p ( @params ) {
	  if ( $p =~ /^rating_([0-9]+)/ ) {
	      my $id = $1;
	      if ( exists $deletedrating{$id} ) {
		  next;
	      }
	      my $rec = Rating::getRecord($id);
	      my $newrec;
	      $$newrec{'rating'} = param("rating_$id");
	      $$newrec{'comment'} = param("comment_$id");
	      my $diffs = $changes->diff({-table=>\%::RatingTable,
					  -row=>$id,
					  -user=>Login::getLoginId(),
					  -old=>$rec,
					  -new=>$newrec,
					  -join_table=>"candidate",
					  -join_id=>$candidate_id,
					  -donulls=>0,
			  });
	      if ( $diffs > 0 ) {
		  updateSimpleRecord({-table=>\%::RatingTable,
				      -old=>$rec,
				      -new=>$newrec,
				      -donulls=>0,
				  });
	      }
	  }
      }
  };
    if ( $changes->size() > 0 || $msg ) {
	if ( $changes->size() > 0 ) {
	    print p("Saved changes.");
	    auditUpdate($changes);
	    print $changes->listHTML({-user=>Login::getLoginRec()});
	}

	if ( !(defined $skipemail && $skipemail) ) {
	    my @mailrecips = Candidate::mailRecipients({-candidate=>$candidate});
	    if ( scalar(@mailrecips) > 0 ) {
		foreach my $user ( @mailrecips ) {
		    if ( $user->{'sendmail'} eq 'Y' ) {
			my $note = "";
			if ( $changes->size() > 0 ) {
			    if ( $$candidate{'owner_id'} eq $user->{'id'} ) {
				$note = "Changes have been made to a candidate owned by you: " .
				    candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
			    } else {
				$note = "Changes have been made to a candidate that has you as a CC: " .
				    candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
			    }
			}
			print p("Changes e-mailed to $user->{'name'} at $user->{'email'}");
			my $sent = sendEmail({-changes=>$changes,
					      -candidate=>$candidate,
					      -owner=>$user,
					      -note=>$note,
					      -comment=>$comment,
					      -commenter=>getLoginName(),
					      -showskips => 1,
					      -message => $msg,
					     });
			if ( !$sent ) {
			    print p("CORRECTION: Nothing sent to $user->{'name'} at $user->{'email'}");
			}
		    }
		}
	    } else {
		print p("No owner or CC for this candidate, no one to e-mail the changes to!");
	    }
	} else {
	    print p("Skip email selected; not sending any email about this change.");
	}

	# Now check to see if the owner changed

	if ( exists $$newcandidate{'owner_id'} && $$newcandidate{'owner_id'} &&
             $$candidate{'owner_id'} ne $$newcandidate{'owner_id'} ) {
	    my $owner = User::getRecord($$newcandidate{'owner_id'});

	    if ( $$owner{'sendmail'} eq 'Y' ) {
                my $note = "This candidate, " .
                    candidateLink({-name=>$candidate->{'name'}, -id=>$candidate->{'id'}}) .
                    ", has been reassigned to you.";
		sendEmail({-changes=>$changes,
			   -candidate=>$candidate,
			   -owner=>$owner,
			   -comment=>$comment,
			   -commenter=>getLoginName(),
			   -note=>$note,
		       });
		print p("Changes e-mailed to the new owner $$owner{'name'} at $$owner{'email'}");
	    }
	}			

    }
    print p("Reloading...", a({-href=>"$reload"},"Back to $$candidate{'name'}"));
    print Footer({-url=>"$self_url"}), end_html, "\n";
}


#sub sendEmail
#{
#    my $argv = shift;
#    argcvt($argv, ["changes", "candidate", "owner"], ["comment", "commenter", "note"]);
#    my $changes = $$argv{'changes'};
#    my $candidate = $$argv{'candidate'};
#    my $owner = $$argv{'owner'};
#
#    ## Mail note to the owner
#
#    my $from = getLoginEmail();
#
#    if ( !$from ) {
#	$from = getValueMatch({
#	    -table=>\%::ParamTable,
#	    -column=>"name",
#	    -equals=>"e-mail-from",
#	    -return=>"value",
#	});
#	if ( !defined $from ) {
#	    $from = $::EMAIL_FROM;
#	}
#    }
#
#    $msg = new Mail::Mailer('sendmail');
#    my $boundary = "**__**__**__**__**__";
#    my $message = "";
#
#    my %headers = (
#		   'From' => $from,
#		   'To' => $$owner{'email'},
#		   'Subject' => "Changes to candidate $$candidate{'name'}",
#		   'MIME-Version' => '1.0',
#		   'Content-Type' => 'multipart/mixed;boundary="' . $boundary . '"',
#		   );
#
#
#    $msg->open(\%headers);
#
#    $message .= "This is a multipart message in MIME format.\n\n";
#    $message .= "--$boundary\n";
#
#    my $m = new CGI;
#    $message .= $m->header;
#
#    if ( exists $$argv{'note'} ) {
#	$message .= p($$argv{'note'}) . "\n";
#    } else {
#	$message .= p("Changes have been made to this candidate: ", "\n",
#		     Candidate::candidateLink({-name=>$$candidate{'name'},
#					       -id=>$$candidate{'id'}})) . "\n";
#    }
#
#
#    $message .= $changes->listHTML();
#    $message .= br() . "\n";
#
#    if ( exists $$argv{'comment'} && $$argv{'comment'} ) {
#	my $commenter = exists $$argv{'commenter'} ? $$argv{'commenter'} : "(unknown)";
#	$message .= p(b("Comment added by $commenter:")) . "\n";
#	$message .= p(Utility::cvtTextarea($$argv{'comment'})) . "\n";
#    }
#
#    $message .= "\n--$boundary--\n";
#    print $msg $message;
#
##    open FF, ">>/tmp/tracker-email.txt" and do {
##	print FF "--------------------------------------------To: $$owner{'email'}\n";
##	print FF $message;
##	close FF;
##    };
#    $msg->close;         # complete the message and send it
#}
#


#obsolete

sub doDelete
{
    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $pk = shift;
    print doHeading({-title=>"Delete Job Candidate"});

  BODY: {

      my $query = "DELETE from candidate WHERE id = " . SQLQuote($pk);
      SQLSend($query);
      print p("Entry deleted");
  };
    print Footer({-url=>"$self_url"}), end_html, "\n";
}


sub doGet
{
    print header;
    ConnectToDatabase();
    my $user = Login::getLoginRec();

    ## This script is called when the "Reject this candidate" link is used.
    ## It prompts for a comment and then swaps out to a URL that processes
    ## the reject request.  If the user hits Cancel, the URL is not replaced.

    my $GET_JSCRIPT = <<END;
function doreject(url)
{
    var comment = prompt("Reason for reject: ", "Rejected: ");
    if ( comment != null ) {
        url = url + ";comment=" + comment;
        document.location = url;
    }
}
END

    ## $self_url can be used to come back to this page later

    my $self_url = url(-absolute => 1, -query=>1);
    my $id = param("id");

    ## Fetch the candidate record and make sure that it isn't hidden - only
    ## admins can see hidden URLS

    my $candidate = Candidate::getRecord($id);
    if ( $$candidate{'hide'} && !isAdmin() ) {
        doAccessDenied();
        return;
    }

    my $actionjs = OpeningAction::generateActionJavaScript();

    print doHeading({
        -title=>"Candidate $$candidate{'name'}",
	    -script=>[
	     {
		 -language=>'JavaScript1.2',
		     -src=>'javascript/actionlist.js'
	     },
	     {
		 -language=>'JavaScript1.2',
		     -code=>$GET_JSCRIPT,
	     },
	     {
		 -language=>'JavaScript1.2',
		     -code=>$actionjs
	     }
	    ],
	    -onload=>"fixActionList($$candidate{'opening_id'},'action_id_new', $$candidate{'action_id'});",
		    });

    print Layout::startForm({-action=>url(-absolute=>1)});
    param("op", "edit");
    print hidden({-name=>"op", -default=>"edit"});
    print hidden({-name=>"id", -default=>"$id"});
    print submit({-name=>"Edit"});
    print Layout::endForm;

    Recruiter::mailSubject("Concerning $$candidate{'name'}");
    print doStaticValues({-table=>\%::CandidateTable,
			  -record=>$candidate,
			 -class=>"striped"});

    print h2("Actions"), "\n";
    print start_div({-style=>""});

    print start_ul, "\n";
    print li({-class=>"clickable"},a({-href=>"schedule.cgi?candidate_id=$id"},
	    "Create an interview schedule")), "\n";
    print li({-class=>"clickable"},a({-href=>"reference-letter.cgi?id=$id"}, "Create ref check letter"));

    my $auditurl = url(-absolute=>1) . "?op=audit&id=$id";
    print li({-class=>"clickable"},a({-href=>$auditurl}, "Show change log")), "\n";
    my $rejecturl = url(-absolute=>1) . "?op=reject&id=$id";
    if ( $user->{'changestatus'} eq 'Y' || isAdmin() ) {
        print li({-class=>"clickable"},a({-href=>"javascript:doreject('$rejecturl');"}, "Reject candidate")), "\n";
    }
    print end_ul;

    print end_div, "\n";

    print h2("Attached Documents");
    my @docs = getRecordsMatch({
	-table=>\%::DocumentTable,
	-column=>"candidate_id",
	-value=>$id,
    });
    if ( scalar @docs == 0 ) {
	print p("None.");
    } else {
	print start_table({-cellpadding=>"4"});
	print Tr(
#		 td(b("Created")),
#		 td(b("Contents")),
#		 td(b("Filename")),
		 th({-class=>"inline"},"Created"),
		 th({-class=>"inline"},"Contents"),
		 th({-class=>"inline"},"Filename"),
		 );
	foreach my $d ( @docs ) {
	    print Tr(
		     td($d->{'creation'}),
		     td($d->{'contents'}),
		     td(Document::link({
                         -id=>$d->{'id'},
                         -name=>$d->{'filename'},
                     })),
		     );
	}
	print end_table;
    }

    ##
    ## Comments section
    ##

    print h2("Comments"), "\n";
    my @comments = getRecordsMatch({
	-table=>\%::CommentTable,
	-column=>"candidate_id",
	-value=>$id,
    });

    if ( scalar @comments == 0 ) {
	print p("None.");
    } else {
	my $url = url(-absolute=>1);
	print p(a({-href=>"$url?op=viewallcomments&candidate=$id"},"View Full Comments Together"));
	print start_table({-cellpadding=>"4"});
	print Tr(
	    th({-class=>"inline"},"When"),
	    th({-class=>"inline"},"Submitted By"),
	    th({-class=>"inline"},"Confidential?"),
	    th({-class=>"inline"},"View"),
	    th({-class=>"inline"},"Edit"),
	    th({-class=>"inline"},"Text . . ."),
		 );
	foreach my $c ( @comments ) {
	    my $r = User::getRecord($c->{'user_id'});
	    if ( $$c{'confidential'} eq 'Y' and $$r{'id'} != Login::getLoginId() ) {
		next;
	    }
	    my $more = length $c->{'comment'} > 60 ? " . . ." : "";

	    print Tr(
		     td($c->{'creation'}),
		td("$$r{'name'}"),
		td({-align=>"center"},$c->{'confidential'}),
		     td(a({-href=>"$url?op=viewcomment;id=$c->{'id'};candidate=$id"}, "View")),
		     td(a({-href=>"$url?op=editcomment;id=$c->{'id'};candidate=$id"}, "Edit")),
		     td(($$c{'confidential'} eq 'Y' ? "[Click \"View\" to see]" : (Utility::cvtTextline(substr($c->{'comment'},0,60)) . $more))),
		     );
	}
	print end_table;
    }

    ##
    ## Ratings section
    ##

    print h2("Ratings"), "\n";
    print Candidate::formatRatings($id);

    ##
    ## Schedules list, allowing view and edit
    ##

    Candidate::getInterviewers($id);

    print h2("Schedules"), "\n";
    if ( isLoggedIn() ) {
	print p(a({-href=>"schedule.cgi?candidate_id=$id"}, "Create an interview schedule")), "\n";
    }

    my @schedules = getRecordsMatch({
	-table=>\%::InterviewTable,
	-column=>"candidate_id",
	-value=>$id,
    });
    if ( scalar @schedules == 0 ) {
	print p("None.");
    } else {
	print start_table({-cellpadding=>"4"});
	print Tr(
		 th({-class=>"inline"},"When"),
		 th({-class=>"inline"},"Status"),
		 th({-class=>"inline", -colspan=>"1", -align=>"center"}, b("View for")),
		 th({-class=>"inline"},"Edit"),
		 th({-class=>"inline"},"Who"),
		 th({-class=>"inline"},"Description"),
		 );
	foreach my $s ( @schedules ) {
	    print start_Tr, "\n";
	    print td({-valign=>"top"}, $s->{'date'}), "\n";
	    print td({-valign=>"top"}, $s->{'status'}), "\n";
	    print td({-valign=>"top"}, a({-href=>"schedule.cgi?op=format;schedule_id=$s->{'id'};type=interviewer"}, "Interviewers"),br,
		     a({-href=>"schedule.cgi?op=format;schedule_id=$s->{'id'};type=candidate"}, "Candidate"),br,
		     a({-href=>"schedule.cgi?op=view&schedule_id=$s->{'id'}"}, "Other"));
	    print td({-valign=>"top"}, a({-href=>"schedule.cgi?op=edit&schedule_id=$s->{'id'}"}, "Edit")), "\n";
	    print start_td({-valign=>"top"}), "\n";
	    my $interviewers = Schedule::getInterviewers($s->{'id'});
	    my $lines_printed = 0;
	    foreach my $interviewer_name ( keys %$interviewers ) {
		$lines_printed++ && print br;
		print User::getName($interviewer_name), "\n";
	    }
	    print end_td, "\n";
	    print td({-valign=>"top"}, $s->{'purpose'}), "\n";
	    print end_Tr, "\n";
	}
	print end_table;
    }

    ##
    ## Add comments, ratings, upload documents
    ##

    if ( isLoggedIn() ) {

	print start_table({-border=>"0",
			   -cellspacing=>0,
			   -cellpadding=>4,
			   -bgcolor=>"#e0e0e0"}),
	start_Tr, start_td;
	print Layout::startForm({-action=>url(-absolute=>1), -enctype=>'multipart/form-data'});
	print h1("Make changes to $$candidate{'name'}");

	print h2(a({-name=>"comment"}, "Add a Comment")), "\n";
	my $links = OpeningEvaluation::getInsertLinks(Layout::getForm(),$candidate->{'opening_id'}, 'comment_0');
	print $links;
	param("op", "addstufffinish");
	print hidden({-name=>"op", -default=>"addstufffinish"});
	print hidden({-name=>"candidate_id", -default=>$id});

	##
	## Add a Comment
	##

	print start_table;
	print Tr(
		 td({
		     -align=>"right",
		 },
		    b("Comment:"),
		    br,
		    Template::getMenu({-table=>"comment",
				-column=>"comment",
				-control=>"comment_0",
			    }),

		    ), "\n",
		 td(textarea({
		     -name=>"comment_0",
		     -rows=>"12",
		     -columns=>"80"
		     })), "\n"
	    );
	print Tr(
	    td({-align=>"right"},
	       b("Confidential?"),
	    ), "\n",
	    td(
		Layout::doSingleFormElement({
                        -table=>\%::CommentTable,
                        -column=>"confidential",
                        -record=>$candidate,
                        -form=>undef,
                        -div=>undef,
			    -suffix => "_0",
					    }),
	    )
	    );
	print end_table, "\n";

	##
	## Add a rating
	##

	my $me = getLoginId();
	my @ratings = getRecordsMatch({
	    -table=>\%::RatingTable,
	    -column=>["candidate_id","user_id"],
	    -value=>[$id,$me],
	});
	print h2(a({-name=>"rating"}, "Add a Rating")), "\n";
	my %rec;
	$rec{'user_id'} = getLoginId();
	$rec{'candidate_id'} = $id;
	$rec{'creation'} = Utility::now();
	print doEntryForm({-table=>\%::RatingTable,
			   -hide=>['user_id', 'candidate_id', 'creation'],
			   -record=>\%rec,
		       -nocolor=>1});

	##
	## Recommend a next action and owner
	##    action_id_new ... next action
	##    owner_id_new .... next owner
	##    status_new ...... new status
	##    addtocc ......... checked to add owner to CC list
	##

	if ( $user->{'changestatus'} eq 'Y' || isAdmin() ) {
	    print h2("Set the Status, Next Action and Owner"), "\n";
	} else {
	    print h2("Set the Next Action and Owner"), "\n";
	}
	print hidden({-name=>"id_new", -default=>"$id"});
	print start_table, "\n";

	# Only show the status field if this user can change it.

	if ( $user->{'changestatus'} eq 'Y' || isAdmin()) {
	    print Tr(
		td({-align=>"right"},b("New Status:")), "\n",
		td(
		    Layout::doSingleFormElement({  ## XXX
			-table=>\%::CandidateTable,
			-column=>"status",
			-record=>$candidate,
			-form=>undef,
			-div=>undef,
			-suffix => "_new",
						})), "\n",
		);
	}

	## TODO Only show actions appropriate to this candidate
	
	print Tr(
		 td({-align=>"right"},b("Next Action:")), "\n",
		 td(
		    Layout::doSingleFormElement({  ## XXX
			-table=>\%::CandidateTable,
			-column=>"action_id",
			-record=>$candidate,
			-form=>undef,
			-div=>undef,
			    -suffix => "_new",
			    -id => "action_id_new",
			})), "\n",
		 );

	my $doAddCC = !Cc::isIncluded($candidate->{'owner_id'}, $id);
	print Tr(
		 td({-align=>"right"},b("Next Owner:")), "\n",
		 td(
		    Layout::doSingleFormElement({  ## XXX
			-table=>\%::CandidateTable,
			-column=>"owner_id",
			-record=>$candidate,
			-form=>undef,
			-div=>undef,
			-suffix => "_new",
			}),
		    $doAddCC ? checkbox({
			-name=>"addtocc",
			-label=>"Add " . User::getName($candidate->{'owner_id'}) . " to CC list",
		    }) : "",
		    ), "\n",
		 );
	print end_table, "\n", br, "\n";

	##
	## Upload a document
	##

	print h2(a({-name=>"upload"}, "Upload a Document")), "\n";

	print start_table, "\n";
	print Tr(
		 td({-align=>"right"},b("Upload File:")), "\n",
		 td(filefield({-name=>"filename", -size=>"30"})), "\n",
		 );
	print Tr(
		 td({-align=>"right"},b("Description:")), "\n",
		 td(textfield({-name=>"contents", -size=>"30"})), "\n",
		 );
	print end_table, "\n", br, "\n";

        print "Optional top paragraph for the outgoing email about changes (plain text): ", br, textarea({-name=>"msg", -columns=>80, -rows=>3}), br, br, "\n";
	print checkbox({-name=>"skipemail", -label=>"Do not send email"}),br, br, "\n";

	## submit

	print submit({-name=>"Save Additions"}), " to $$candidate{'name'}\n";
	print Layout::endForm, "\n";
	print end_table;


    } else {
	print p("Log in first then you can add comments, schedules, ratings, and upload files.");
    }

    print Footer({-url=>"$self_url"}), end_html;
}

##
## op=viewcomment
##
## Note: the candidate parameter is no longer needed.
##


sub doViewComment
{
    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $id = param("id");

    my $comment = Comment::getRecord($id);

    my $candidate_id = $$comment{'candidate_id'};
    my $candidate = Candidate::getRecord($candidate_id);

    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }

    my $reload = url(-absolute=>1) . "?op=get;id=$candidate_id";
    my $username = User::getName($$comment{'user_id'});

    print doHeading({-title=>"By $username on $$comment{'creation'}"});

    print p(i("Concerning $$candidate{'name'}"));
    print Utility::cvtTextarea($$comment{'comment'}), br();

    my @comment_id = getPKsMatch({-table=>\%::CommentTable,
				  -column=>"candidate_id",
				  -value=>$candidate_id});
    my ($prev, $next);
    $prev = 0;
    $next = 0;
    for ( my $i=0 ; $i<scalar(@comment_id) ; $i++ ) {
	if ( $comment_id[$i] == $id ) {
	    if ( $i>0 ) {
		$prev = $comment_id[$i-1];
	    }
	    if ( $i<scalar(@comment_id)-1 ) {
		$next = $comment_id[$i+1];
	    }
	}
    }

    print start_p;
    if ( $prev > 0 ) {
	my $link = url(-absolute=>1) . "?op=viewcomment;id=$prev;candidate=$candidate_id";
	print a({-href=>$link}, "< Previous comment");
	if ( $next > 0 ) {
	    print " | ";
	}
    }
    if ( $next > 0 ) {
	my $link = url(-absolute=>1) . "?op=viewcomment;id=$next;candidate=$candidate_id";
	print a({-href=>$link}, "Next comment >");
    }
    print end_p;

    print hr, p(a({-href=>$reload}, "Back to $$candidate{'name'}"));
    print Footer({-url=>"$self_url"}), end_html;
}

sub doViewAllComments
{
    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $candidate_id = param("candidate");
    my $reload = url(-absolute=>1) . "?op=get;id=$candidate_id";

    my $candidate = Candidate::getRecord($candidate_id);

    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }
    my $candidate_name = $$candidate{'name'};
    print doHeading({-title=>"Comments on $candidate_name"});

    my @comments = getRecordsMatch({
	-table=>\%::CommentTable,
	-column=>"candidate_id",
	-value=>$candidate_id,
    });
    foreach my $c ( @comments ) {
	my $username = User::getName($c->{'user_id'});
	print h2("By $username on $c->{'creation'}");
	print p(Utility::cvtTextarea($c->{'comment'})), hr();
    }
    print p(a({-href=>$reload}, "Back to the candidate page"));
    print Footer({-url=>"$self_url"}), end_html;
}



sub printUploadSection
{
    my $id = shift;

    print hr(), h2(a({-name=>"upload"},"Upload a document"));
    print Layout::startForm({-action=>url(-absolute=>1), -enctype=>'multipart/form-data'});
    param("op", "uploadfinish");
    print hidden({-name=>"op", -default=>"uploadfinish"});
    print hidden({-name=>"id", -default=>"$id"});

    print start_table;
    print Tr(
	     td({-align=>"right"},"Upload File:"),
	     td(filefield({-name=>"filename", -size=>"30"}))
	     );
    print Tr(
	     td({-align=>"right"},"Description:"),
	     td(textfield({-name=>"contents", -size=>"30"}))
	     );
    print end_table;

    print submit({-name=>"Upload"});;
    print Layout::endForm;

}


##
## doUpload
##
## This is twisty logic.  Because the upload section is on the same page as the
## candidate information, if the user is not logged in, force a login and then redirect
## to the candidate page at the upload document mark
##

sub doUpload
{
    my $id = param("id");
    param("op","get");
    my $reload = url(-absolute => 1, -query=>1) . "#upload";
    doMustLogin($reload);

    my $q = new CGI;
    print $q->redirect(-location=>$reload, -method=>"get");
}

sub doUploadFile
{
    my $argv = shift;
    argcvt($argv, ['fileparam', 'contentparam'], ['candidate_id', 'changes', 'tmp']);
    my $fileparam = $$argv{'fileparam'};
    my $contentparam = $$argv{'contentparam'};
    my $candidate_id = $$argv{'candidate_id'};
    my $changes = $$argv{'changes'};
    my $tmp = $$argv{'tmp'};

    my $fn = param($fileparam);
    my $contents = param($contentparam);

    my $insertid;
    my $totalbytes = 0;;

    $fn =~ s,^.*(\\|/)(.+)$,$2,;	
  READ:
    {
	no strict;
	my $buffer;
	my $bytesread;
	my ($fullfile, $webdir, $fulldir);

	if ( length($fn) > 0 ) {
	    my $fh = upload($fileparam);
            if ( !$fh ) {
                print Utility::errorMessage($fn, " does not exist.");
                last READ;
            }

	    ##
	    ## If "tmp" is specified as an argument, then copy the upload files into the Document table
            ## and mark them as temporary
	    ##

            my $data;
	    $totalbytes = 0;
	    while ($bytesread=read($fh,$buffer,1024*256)) {
                $data .= $buffer;
		$totalbytes += $bytesread;
	    }
	    close $fh;

            ## The WHOLE file contents is in $data now.  Store it in the documents table.

            my $record;
            $record->{'size'} = $totalbytes;
            $record->{'data'} = $data;
            $record->{'filename'} = $fn;
            $record->{'contents'} = $contents;
            if ( $candidate_id ) {
                $record->{'candidate_id'} = $candidate_id;
            }
            if ( $tmp ) {
                $record->{'temporary'} = $tmp;
            }
            $insertid = Database::writeSimpleRecord({
                -table=>\%::DocumentTable,
                -record=>$record,
                -allownulls=>1,
            });

	}
    };
    return ($totalbytes,$insertid);
}


##
## doAddComment/doAddRating
##
## This is twisty logic.  Because the add comment section is on the same page as the
## candidate information, if the user is not logged in, force a login and then redirect
## to the candidate page at the add comment mark
##

sub doAddComment
{
    my $candidate_id = param("id");
    param("op","get");
    my $reload = url(-absolute => 1, -query=>1) . "#comment";
    doMustLogin($reload);

    my $q = new CGI;
    print $q->redirect({-location=>$reload, -method=>"get"});
}
sub doAddRating
{
    my $candidate_id = param("id");
    param("op","get");
    my $reload = url(-absolute => 1, -query=>1) . "#rating";
    doMustLogin($reload);

    my $q = new CGI;
    print $q->redirect({-location=>$reload, -method=>"get"});
}

##
## doAddStuffFinish - process the POST from adding a comment or rating or file
##
## gather parameters, add to the given candidate,
## update audit trail, send e-mail
##

sub doAddStuffFinish
{
    doMustLogin(url(-absolute => 1, -query=>1));

    my ($rating_id, $comment_id, $upload_id);

    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);

    my $candidate_id = param("candidate_id");
    my $candidate = Candidate::getRecord($candidate_id);

    my $user_id = getLoginId();
    my $user = User::getRecord($user_id);
    my $user_name = User::getName($user_id);

    my $url = url(-absolute=>1);
    my $reload = "$url?op=get&id=$candidate_id";
    print doHeading({ -title=>"Save Additions",
		       -head=>meta({-http_equiv=>"Refresh",
				    -content=>"$::REFRESH;URL=$reload"})});

    my $changes = new Changes(Converter::getConverterRef());


    ##
    ## First save the comment, if any
    ##

    my $haveComment = 0;

    ##
    ## Adding a Comment
    ##
    ## Only process a comment if it exists and is more than just whitespace
    ##
    ## The comment param has a "_0" suffix so that InsertFromParams can sort out
    ## the form data that is specific to the comment table.
    ##

    my $comment = param("comment_0");
    my $confidential = param ("confidential_0");
    if ( defined $comment && $comment !~ /^\s*$/ ) {
	$haveComment = 1;
	my $rec;
	$$rec{'candidate_id'} = $candidate_id;
	$$rec{'user_id'} = $user_id;
	$$rec{'confidential'} = $confidential;
	$comment_id = doInsertFromParams({-table=>\%::CommentTable,
					  -changes=>$changes,
					  -suffix=>"_0",
					  -join_table=>"candidate",
					  -join_id=>$candidate_id,
					  -record=>$rec,
				       });
	$changes->add({-table=>"candidate",
		       -row=>$candidate_id,
		       -column=>"comment",
		       -type=>"ADD",
		       -new=>$comment_id,
		       -user=>$user_id});
	
	print p("Saved comment successfully, #$comment_id."), "\n";
    }

    ##
    ## Adding a Rating
    ##
    ## Only add the rating if one is given and it's not just whitespace
    ##

    my $haveRating = 0;
    my $rating = param("rating");
    if ( defined $rating && $rating !~ /^\s*$/ ) {
	$haveRating = 1;
	$rating_id = doInsertFromParams({
            -table=>\%::RatingTable,
            -changes=>$changes,
            -join_table=>"candidate",
            -join_id=>$candidate_id,
        });
	$changes->add({
            -table=>"candidate",
            -row=>$candidate_id,
            -column=>"rating",
            -type=>"ADD",
            -new=>$rating_id,
            -user=>$user_id,
        });
	print p("Saved rating successfully, #$rating_id."), "\n";
    }

    ##
    ## Check for changed "status", next action" and "owner"
    ##
    ##    status_new ...... status
    ##    action_id_new ... next action
    ##    owner_id_new .... next owner
    ##    addtocc ......... checked to add owner to CC list
    ##

    my $haveChanges = 0;
    my $candidateChanges = new Changes;
    doUpdateFromParams({
	-table=>\%::CandidateTable,
	-record=>$candidate,
	-changes=>$candidateChanges,
	-suffix => "_new",
      });

    if ( defined param("addtocc") && param("addtocc") eq "on" ) {
	if ( Cc::add($$candidate{'owner_id'}, $candidate_id) ) {
	    $changes->add({
		-table=>"candidate",
		-row=>$candidate_id,
		-column=>"cc",
		-type=>"ADD",
		-new=>User::getName($$candidate{'owner_id'}),
		-user=>getLoginId(),
	    });
	}
    }

    if ( $candidateChanges->size() > 0 ) {
	$haveChanges = 1;
	if ( $changes ) {
	    $changes->merge($candidateChanges);
	}
    }


    ##
    ## Add a document upload
    ##

    my $haveUpload = 0;
  UPLOAD: {
      my $remotefile = param('filename');
      my $contents = param("contents");

      if ( $remotefile =~ /^\s*$/ ) {
	  last UPLOAD;
      }

      ## XXX

      my ($bytes, $pk) = doUploadFile({
          -fileparam=>"filename",
          -contentparam=>"contents",
          -candidate_id=>"$candidate_id",
          -changes=>$changes,
      });

      if ( $bytes <= 0 ) {
	  print p("The file \"$fn\" is empty, nothing uploaded.");
          $haveUpload = 0;
	  last UPLOAD;
      }

      $haveUpload = 1;
      $changes && $changes->add({
	  -table=>"candidate",
	  -row=>$candidate_id,
	  -column=>"document",
	  -type=>"ADD",
	  -new=>"$pk",
	  -user=>getLoginId(),
      });

      if ( $bytes > 0 ) {
	  print p("Uploaded $remotefile ($bytes bytes) successfully.");
	  updateModtime($candidate_id);
      } else {
	  print p("Empty file \"$fn\" - nothing saved.");
	  $haveUpload = 0;
      }
  };

    my $msg = param("msg");
    my $haveMessage = 0;
    if ( defined $msg && $msg !~ /^\s*$/ ) {
        $haveMessage = 1;
    }

    if ( $haveRating || $haveComment || $haveUpload || $haveChanges || $haveMessage) {
	auditUpdate($changes);
	updateModtime($candidate_id);
	print $changes->listHTML({-user=>Login::getLoginRec()});
	
	##
	## Send e-mail to the owner and the CCs
	##
	## reload the candidate record
	##
	Candidate::invalidateCache($candidate_id);
	$candidate = Candidate::getRecord($candidate_id);

	## Check "do not email" checkbox
	my $skipemail = param("skipemail");

	if ( !(defined $skipemail && $skipemail) ) {
	    my @mailrecips = Candidate::mailRecipients({-candidate=>$candidate});
	    if ( scalar(@mailrecips) > 0 ) {
		foreach my $user ( @mailrecips ) {
		    if ( $user->{'sendmail'} eq 'Y' ) {
			sendEmail({-changes=>$changes,
				   -candidate=>$candidate,
				   -owner=>$user,
				   -comment=>$comment,
				   -commenter=>$user_name,
				   -message=>$msg,
				  });
			print p("Changes e-mailed to $user->{'name'} at $user->{'email'}");
		    }
		}
	    } else {
		print p("No one has requested e-mail updates for this candidate!");
	    }
	} else {
	    print p("Skip email checked, sending no emails");
	}
    } else {
	print p("Nothing added or changed, nothing saved.");
    }
    print p("Reloading...", a({-href=>"$reload"},"Back to $$candidate{'name'}"));
    print Footer({-url=>"$self_url"}), end_html;
}




## Edit comments

sub doEditComment
{
    doMustLogin(url(-absolute => 1, -query=>1));

    print header;
    ConnectToDatabase();

    my $comment_id = param("id");
    my $candidate_id = param("candidate");
    my $table = \%::CommentTable;
    my $candidate = Candidate::getRecord($candidate_id);

    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }


    my $self_url = url(-absolute => 1, -query=>1);

    print doHeading({-title=>"Edit $table->{'heading'}"});

    my $record = Comment::getRecord($comment_id);

    param("op", "editcommentfinish");
    print Layout::startForm({-action=>url(-absolute=>1)}), "\n",
    hidden({-name=>"op", -default=>"editcommentfinish"}), "\n";

    print hidden({-name=>"id", -default=>"$comment_id"});
    print hidden({-name=>"candidate", -default=>"$candidate_id"});
    print doEditForm({-table=>$table, -record=>$record});
    print submit({-name=>"Update"}), "\n";
    print Layout::endForm;

    print Footer({-url=>"$self_url"}), end_html, "\n";
}

sub doEditCommentFinish
{
    print header;
    ConnectToDatabase();

    my $candidate_id = param("candidate");
    my $comment_id = param("id");
    my $self_url = url(-absolute => 1, -query=>1);

    my $url = url(-absolute=>1);
    my $reload = "$url?op=get&id=$candidate_id";
    print doHeading({-head=>meta({-http_equiv=>"Refresh",-content=>"$::REFRESH;URL=$reload"}),
		     -title=>"Finish Edit Comment",
		 });

    my $comment = Comment::getRecord($comment_id);
    my $changes = new Changes(Converter::getConverterRef());

    doUpdateFromParams({-table=>\%::CommentTable,
			-record=>$comment,
			-changes=>$changes,
			-join_table=>"candidate",
			-join_id=>$candidate_id,
		    });
    auditUpdate($changes);
    print $changes->listHTML({-user=>Login::getLoginRec()});

    print p(a({-href=>$reload}, "Reloading..."));
    print Footer({-url=>"$self_url"}), end_html, "\n";
}

##
## doAudit - show audit trail on the candidate
##

sub doAudit
{
    print header;
    ConnectToDatabase();
    my $candidate_id = param("id"); # candidate_id
    my $self_url = url(-absolute => 1, -query=>1);
    my $reload = url(-absolute=>1) . "?op=get;id=$candidate_id";

    my $candidate = Candidate::getRecord($candidate_id);
    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }

    print doHeading({-title=>"Activity for $$candidate{'name'}"}), "\n";


    my $ch = auditGetRecords({-table=>\%::CandidateTable,
			      -row=>$candidate_id,
			      -join_table=>"candidate",
			      -join_id=>$candidate_id,
			      -converters=>Converter::getConverterRef()});

    print p($ch->size(), " change records.");
    print $ch->listHTML({-user=>Login::getLoginRec()});
#    print $ch->listHTML({-table=>\%::CandidateTable});
    print hr;
    print p(a({-href=>$reload}, "Back to the candidate page"));
    print Footer({-url=>"$self_url"}), end_html;
    print end_html;
}

##
## getNames - fetch and return an array of an array of names of existing
##            candidates.
##
## Builds a hash of words already seen in the names of candidates
## where the value of the hash is an array of (name,id) hashes
##
## {
##     'some_name' => [
##                       { id => the_pk,
##                         name => the_name, },
##                       ...
##                    ],
##     'another_name' => [ ... ],
## }
##

sub getNames
{
    my %result;

    my @candidate = getAllRecords({-table=>\%::CandidateTable});
    foreach my $c ( @candidate ) {

	my $str = $c->{'name'};

	foreach my $item ( namePieces($str) ) {
	    push @{$result{lc($item)}}, { id=>$c->{'id'}, 'name'=>$c->{'name'} };
	}
    }
    return %result;
}

sub namePieces
{
    my $str = shift;
    my %skipwords = ("sr"=>1, "jr"=>1, "iii"=>1);

    $str =~ s/[^\w\s]//g;

    my @words;
    foreach my $w ( grep { length($_)>1 } split(' ',$str) ) {
	unless ( $skipwords{lc($w)} ) {
	    push @words, lc($w);
	}
    }
    return @words;
}

##
## getNameMatches - returns a hash of arrays of hashes.  THe top level key is an integer
##    denoting the number of words that match.  The element of the has is an array
##    of names that match this number of times, where each element of that array
##    is a has of {id, name} as in getNames;
##

sub getNameMatches
{
    my $name = shift;
    my @words = namePieces($name);
    my %known = getNames();
    my %matches;


    foreach my $w ( @words ) {
	if ( exists $known{$w} ) {
	    $matches{$w} = $known{$w};
	}
    }

    my %idmatches;
    foreach my $k ( keys %matches ) {
	foreach my $e ( @{$matches{$k}} ) {
	    $idmatches{$e->{'id'}}->{'count'}++;
	    $idmatches{$e->{'id'}}->{'name'} = $e->{'name'};
	}
    }

    my %result;
    foreach my $k ( keys %idmatches ) {
	push @{$result{$idmatches{$k}->{'count'}}}, {id=>$k,
						     name=>$idmatches{$k}->{'name'}};
    }
#	print Utility::ObjDump(\%result);
    return %result;
}

sub doTest
{
    print header;
    ConnectToDatabase();

    my @skipwords = ("sr", "jr");

    print doHeading({-title=>"Test Page"}), hr;

    my @candidate = getAllRecords({-table=>\%::CandidateTable});
    foreach my $c ( @candidate ) {

	my $str = $c->{'name'};
	$str =~ s/[^\w\s]//g;

	my @seen;
	@seen{@skipwords} = ();

	my @words = ();
	foreach my $item ( grep { length($_)>1 } split(' ',$str) ) {
	    push @words, $item unless exists $seen{lc($item)};
	}

	print b($c->{'name'}), ": ", join(" | ", @words), br;
    }
    print end_html;
}


sub doReject
{
    doMustLogin(url(-absolute => 1, -query=>1));

    print header;
    print doHeading({
        -title=>"Reject Candidate",
    });
    ConnectToDatabase();
    my $id = param("id"); # candidate_id
    my $self_url = url(-absolute => 1, -query=>1);
    my $reload = url(-absolute=>1) . "?op=get;id=$id";

    my $user = getLoginId();
    my $candidate = Candidate::getRecord($id);

    if ( $$candidate{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }

    my %newcandidate = %$candidate;
    my $changes = new Changes(Converter::getConverterRef());
    $newcandidate{'status'} = "REJECTED";
    delete $newcandidate{'action_id'};
#    delete $newcandidate{'owner_id'};

    ## Update the changes record for the candidate entry changes...

    $changes->diff({-table=>\%::CandidateTable,
		    -row=>$id,
		    -user=>$user,
		    -old=>$candidate,
		    -new=>\%newcandidate,
                    -donulls=>1,
                });

    ## Write the candidate record back to the database

    updateSimpleRecord({-table=>\%::CandidateTable,
			-old=>$candidate,
			-new=>\%newcandidate,
                        -donulls=>1,
		    });

    ## Add the rejection comment if there is one

    my $comment = param("comment");

    my $commentchanges = new Changes;
    if ( defined $comment && $comment !~ /^\s*$/ ) {
        my $rec;
        $$rec{'candidate_id'} = $id;
        $$rec{'user_id'} = $user;
	$comment_id = doInsertFromParams({-table=>\%::CommentTable,
					  -changes=>$commentchanges,
					  -join_table=>"candidate",
					  -join_id=>$id,
					  -record=>$rec,
				       });
	$commentchanges->add({-table=>"candidate",
		       -row=>$id,
		       -column=>"comment",
		       -type=>"ADD",
		       -new=>$comment_id,
		       -user=>$user});
	

    }

    if ( $changes->size() > 0 || $commentchanges->size() > 0 ) {
        $changes->merge($commentchanges);

	print p("Saved changes.");
	auditUpdate($changes);
	print $changes->listHTML({-user=>Login::getLoginRec()});

	my @mailrecips = Candidate::mailRecipients({-candidate=>$candidate});
	if ( scalar(@mailrecips) > 0 ) {
	    foreach my $user ( @mailrecips ) {
		if ( $user->{'sendmail'} eq 'Y' ) {
		    my $note;
		    if ( $$candidate{'owner_id'} eq $user->{'id'} ) {
			$note = "Changes have been made to a candidate owned by you: " .
			    candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
		    } else {
			$note = "Changes have been made to a candidate that has you as a CC: " .
			    candidateLink({-name=>$$candidate{'name'}, -id=>$$candidate{'id'}});
		    }
		    sendEmail({-changes=>$changes,
			       -candidate=>$candidate,
			       -owner=>$user,
			       -note=>$note,
#			       -comment=>$comment,
#			       -commenter=>getLoginName(),
			   });
		    print p("Changes e-mailed to $user->{'name'} at $user->{'email'}");
		}
	    }
	} else {
	    print p("No owner or CC for this candidate, no one to e-mail the changes to!");
	}
    }

    print hr;
    print p(a({-href=>$reload}, "Back to the candidate page"));
    print Footer({-url=>"$self_url"}), end_html;
    print end_html;

}

sub updateModtime
{
    my $id = shift;
    SQLSend("UPDATE candidate SET modtime = NOW() where id = " . SQLQuote($id));
}

sub notblank
{
    my $str = shift;
    return !($str =~ /^[\s+]*$/);
}

sub doDump
{
    print header;
    ConnectToDatabase();

    my $self_url = url(-absolute => 1, -query=>1);
    my $id = param("id");
    my %c = Candidate::getRecordById({-table=>\%::CandidateTable, -id=>$id});
    if ( $c{'hide'} && !isAdmin() ) {
	doAccessDenied();
	return;
    }

    print doHeading({-title=>"Candidate $c{'name'}"});


    my @recs = getRecordsMatch({
	-table=>\%::CandidateTable,
	-column=>"candidate.id",
	-value=>$id,
	-dojoin=>2,
    });
    print Utility::ObjDump(\@recs);
    print Footer(),end_html;
}
