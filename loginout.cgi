#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use CGI qw(:standard *table *ol *ul *Tr *script);
use CGI::Carp qw(fatalsToBrowser);

use Layout;
use Login;
use Database;
use Utility;
use User;
use Password;

use Data::Dumper;

require "globals.pl";

##
## Called from the home page
##  op = login
##       param userlist = vX where X is the uderid into the profiles table
##  op = logout

my $op = param("op");

if ( defined $op ) {
  SWITCH: {
	  $op eq "logout" and do {
		  doWebLogout();
		  last SWITCH;
	  };
	  $op eq "loginfinish" and do {
		  doWebLoginFinish();
		  last SWITCH;
	  };
  }
} else {
	doWebLogin();
}

exit(0);

sub doWebLogin
{
    ConnectToDatabase();

    my $link = param("link");

    print header;
    my $heading = "Sign in, please";
    if ( param("heading") ) {
        $heading = param("heading");
    }
    my $message = undef;
    if ( param("message" )) {
	$message = param('message');
    }
    print Layout::doLoginForm({
        -heading=>$heading,
        -link=>$link,
	-message => $message,
    });
    print end_html;
}


##
## This is where a link from a login for should come
##
##
## FORM data used:
##    link -- where to go next
##    login_id -- PK into user table of login user
##


sub doWebLoginFinish
{
    my $link = param ("link");
    
    ## Process a login request
    
    my $userid = param("login_id");
    my $login_name = param("login_name");
    my $password = param("password");
    ConnectToDatabase();

    my $rec;
    my $recs;
    my $message;

    ## If login_name is given, use it

    if ( $login_name ) {
	if ( $login_name =~ /@/ ) {
#	    $message = "Using email address $login_name";
	    $recs = getRecordsMatch({
		-table=>\%::UserTable,
		-column => 'email',
		-value => $login_name,
				   });
	} else {
#	    $message = "Using user name $login_name";
	    $recs = getRecordsMatch({
		-table=>\%::UserTable,
		-column => 'name',
		-value => $login_name
				   });
	}
#	$message .= Dumper($recs);
	if ( $recs && scalar @$recs > 0 ) {
	    $rec = $recs->[0];
	    $userid = $rec->{'id'};
	} else {
	    $rec = undef;
	}
    } else {
	$rec = getRecordById({
	    -table=>\%::UserTable,
	    -id=>$userid,
			     });
    }

    if ( defined $rec &&
         ( (!$password && !$rec->{'password'}) ||
           defined $rec->{'password'}
           && User::matchPassword($password, $rec->{'password'}))) {
        do_cookie_header($userid, $link);
    } else {
        param("password", "");
        param("heading", "Incorrect password, try again");
	param('message', $message) if $message;
        doWebLogin();
    }
}
    
sub doWebLogout
{
    my $link = param("link");
    do_cookie_header("", $link);
}


##
## Send a cookie header and then redirect somewhere.
##
## arg 1 ... username
## arg 2 ... link where to go next.
#

sub do_cookie_header
{
    my ($username, $link) = (@_);

    my $cookie = cookie({
        -name => "login",
        -value => "$username",
	-expires => "+30d",
    });
    print header({
        -Location => "$link",
        -Status => "302",
        -Cookie => "$cookie"});
}

sub getCookies {

# cookies are seperated by a semicolon and a space, this will split
# them and return a hash of cookies
    my(@rawCookies) = split (/; /,$ENV{'HTTP_COOKIE'});
    my(%cookies);
    
    foreach (@rawCookies){
        my ($key, $val) = split (/=/,$_);
        $cookies{$key} = $val;
    }
    
    return %cookies;
}
