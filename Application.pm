# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


##
## Global initialization for this application
##
## This file holds the init code and other things specifi to the applicaiton in this directory.
## It is not shared from directory to directory.
##

package Application;


use 5.00;   
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = qw();

use CGI qw(:standard *p *table *ul *td *Tr);

require "globals.pl";

use Converter;

use Login;
use Opening;
use Action;
use ActionCategory;
use Schedule;
use Comment;
use Document;
use Rating;
use Candidate;
use Layout;
use User;
use Param;
use Database;
use Cc;
use Utility;



my @packages = (
                "Action",
                "ActionCategory",
                "Candidate",
                "Cc",
                "Comment",
                "Document",
                "Opening",
                "Rating",
                "Recruiter",
                "Schedule",
                "User",
                );

##
## Initialize the application
##
## Assumptions:
##    Each package named above has these functions:
##        addConverters .... builds a list of converters for displayable strings
##        convert .......... converts a PK into a displayable string
##

sub Init
{
    no strict 'refs';
    foreach my $p ( @packages ) {

        ## Build the list of converters for this package and add them
        ## to the global list.

        my $converters = {};
        &{$p . "::addConverter"}($converters);
        my $tableName = &{$p . "::getTableName"}();
        $converters->{"$tableName.id"} = \&{$p . "::convert"};
        Converter::addConverter($converters);
    }

    if ( Login::isLoggedIn() ) {
        my $mylist = "query.cgi?op=query;status=NEW;status=ACTIVE;groupby=action;owner_id=" . getLoginId();
        ## XXX Change this to be the user's preferred opening listing if defined
        Layout::setHeadingRight(a({-href=>$mylist}, "My Candidates"));
    }

    Database::setFullTrace(1);
    Database::ConnectToDatabase() || Utility::preHTMLAbort("Connection to Database failed");
    Param::loadCache();
    my $refresh = Param::getValueByName("refresh");
    if ( $refresh ) {
        $::REFRESH = $refresh;
    }

}

## Check that certain application-wide parameters are set

sub checkParams
{
    my $heading = 0;
    my @mustExist = (
                     { 'name'=>"e-mail-from", 'description'=>"User name that the reminder e-mail comes from." },
#                     { 'name'=>"badname", 'description'=>"This is the description" },
                     );

    my $text = "";
    foreach my $val ( @mustExist ) {
        if ( !Param::getValueByName($val->{'name'}) ) {
            if ( !$heading ) {
                $text .= h2("Missing Configuration Values in param Table:");
                $text .= start_ul . "\n";
                $heading = 1;
            }
            $text .= li($val->{'name'} , ": ", $val->{'description'});
        }
    }
    if ( $text ) {
        print end_ul, "\n";
    }

    if ( User::getRecordByName("Set Up User") ) {
        $text .= h2("The Set Up Administration User is still in the database");
        $text .= ul(
                    li("Remove \"Set Up User\" once you have added your own user with Admin capability: ",
                       a({-href=>"manage.cgi?table=user"}, "Edit user table")),
                    );
    }

    if ( $text ) {
        initializationError($text);
    }

}

sub initializationError
{
    my $text = shift;
    print table({-border=>"8",-cellspacing=>"8", -cellpadding=>"8"},
                Tr(
                   td({-bgcolor=>"#ffff00"},
                      $text
                      ),
                   ),
                ), "\n";
}


1;


