#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img *p -nosticky);

require "globals.pl";
use ParamTable;

use Layout;
use Login;
use Database;
use Application;
use Utility;
use Document;

Application::Init();

# In must-log-in mode, make sure we're logged in

my $mustLogIn = Param::getValueByName('must-log-in');
if ( $mustLogIn && ref $mustLogIn ) {
    $mustLogIn = $mustLogIn->{'value'};
}
if ( $mustLogIn && !isLoggedIn() ) {
    doMustLogin(self_url());;
}

if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "go" and do {
          doGo();
          last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
    ConnectToDatabase();
    my $id = param("id");
    if ( !$id ) {
        print doDocumentError("Error: Cannot call document.cgi without a document id", 1);
        return;
    }

    ## Validate that the candidate is not hidden

    my $document = Document::getRecord($id);
    if ( !$document ) {
        print doDocumentError("Document #$id does not exist.", 1);
        return;
    }

    my $candidate = Candidate::getRecord($$document{'candidate_id'});
    if ( !$candidate ) {
        print doDocumentError("The candidate for document #$id does not exist.");
        return;
    }

    if ( $$candidate{'hide'}  && !isAdmin() ) {
        print header;
        Layout::doAccessDenied();
        return;
    }

    ## Document exists
    ## Candidate exists
    ## Candidate's document can be viewed
    ## Therefore, deliver the document



    my $header;
    if ( $$document{'filename'} =~ /.*\.pdf/ ) {
	$header = header({
	    -type=>"application/pdf",
			 });
    } else {
	$header = header({
	    -type=>"application/x-download",
	    -attachment=>$$document{'filename'},
			 });
    }

    print $header, $$document{'data'};
    return;
                                         
}

sub doDocumentError
{
    my ($str,$needHeader) = (@_);
    my $result = "";

    if ( $needHeader ) {
        $result .= header;
    }
    $result .= start_html;
    $result .= p($str);
    $result .= end_html;
    return $result;
}
    
#sub doGo
#{
#    print header;
#}
