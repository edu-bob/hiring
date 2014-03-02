# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


##
## Email routines

package Email;


use 5.00;   
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

@EXPORT = qw(
             &sendEmail
             );

@EXPORT_OK = qw();

use CGI qw(:standard *p);
use Data::Dumper;
use Mail::Mailer;
use File::Path;

use Changes;
use Argcvt;
use Utility;
use Candidate;
use Login;
use Database;

require "globals.pl";

##
## sendEmail - send an e-mail message notifying someone that changes have been made
##             to a candidate.
##
## Note: this was factored out of the candidate handler and so is quite specific to
##       creating an e-mail specific to candidate changes.
##
## Required parameters:
##   candidate .... ref to the relevant candidate record
##   owner ........ person to send the e-mail to.
## Optional parameters:
##   changes ...... ref to a changes record that has the accumulated changes
##   comment ...... a comment on a candidate added as a part of this change
##   commenter .... ref to a user record of the person who made the comment
##   note ......... A message to replace the standard "Changes have been made to ..." line
##   showskips .... true then print a message about skipped columns
##
## Configuration parameters:
##   e-mail-from .. the e-mail address of the entity that the e-mail comes from if
##                  there is no one currently logged into the tracker causing this
##                  note to be sent.
##

sub sendEmail
{
    my $argv = shift;
    argcvt($argv, ["candidate", "owner"], ["changes", "comment", "commenter", "note", 'showskips']);
    my $candidate = $$argv{'candidate'};
    my $owner = $$argv{'owner'};

    # Don't send email if nothing to send

    my $empty = 1;

    ## Determine who the note should be "From":
    ##    - by default it is the user currently logged in
    ##    - if no one logged in, get this from the param table

    my $from = getLoginEmail();

    if ( !$from ) {
	$from = Param::getValueByName("e-mail-from");
	if ( !defined $from ) {
	    $from = $::EMAIL_FROM;
	}
    }

    ## Construct the e-mail object as a HTML message

    my $boundary = "**__**__**__**__**__";
    my $message = "";

    $message .= "This is a multipart message in MIME format.\n\n";
    $message .= "--$boundary\n";

    my $m = new CGI;
    $message .= $m->header;

    if ( exists $$argv{'note'} ) {
	$message .= p($$argv{'note'}) . "\n";
    } else {
	$message .= p("Changes have been made to this candidate: ", "\n",
		     Candidate::candidateLink({-name=>$$candidate{'name'},
					       -id=>$$candidate{'id'}})) . "\n";
    }

    ##
    ## If there are changes in a "changes" structure to report, add them to
    ## the e-mail message here.
    ##

    if ( exists $$argv{'changes'} && $$argv{'changes'}  ) {
        my $tbl = $$argv{'changes'}->listHTML({-user=>$owner, -showskips=>$$argv{'showskips'}});
        if ( $tbl ) {
            $message .= $tbl;
            $empty = 0;
        }
    }
    $message .= br() . "\n";

    ##
    ## If there is a comment field, add it to the e-mail message here.
    ##

    if ( exists $$argv{'comment'} && $$argv{'comment'} ) {
	my $commenter = exists $$argv{'commenter'} ? $$argv{'commenter'} : "(unknown)";
	$message .= p(b("Comment added by $commenter:")) . "\n";
	$message .= p(Utility::cvtTextarea($$argv{'comment'})) . "\n";
        $empty = 0;
    }

    $message .= "\n--$boundary--\n";
    if ( !$empty ) {
        sendHtmlEmail({
            -from => $from,
            -to => $$owner{'email'},
            -subject => "Changes to candidate $$candidate{'name'}",
            -boundary => $boundary,
            -body => $message,
                      });
    }

#    open FF, ">>/tmp/tracker-email.txt" and do {
#	print FF "--------------------------------------------To: $$owner{'email'}\n";
#	print FF $message;
#	close FF;
#    };
    return !$empty;
}


sub sendHtmlEmail
{
    my $argv = shift;
    argcvt($argv, ["from", "to", "subject", "body", "boundary"], []);

    my $msg = new Mail::Mailer('sendmail');
    my %headers = (
		   'From' => $argv->{'from'},
		   'To' => $argv->{'to'},
		   'Subject' => $argv->{'subject'},
		   'MIME-Version' => '1.0',
		   'Content-Type' => 'multipart/mixed;boundary="' . $argv->{'boundary'} . '"',
		   );


    $msg->open(\%headers);
    print $msg $argv->{'body'};
    $msg->close;         # complete the message and send it
}

1;

