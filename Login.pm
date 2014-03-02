# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Login;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(&isLoggedIn
             &getLoginId
             &getLoginName
             &getLoginEmail
             &doLogout
             &isAdmin
             &canSeeSalary
             );

@EXPORT_OK = qw();              # Symbols to export on request

require "globals.pl";
use UserTable;


use CGI qw(:standard);
use Database;
use User;

sub isLoggedIn
{
    return defined cookie("login");
}

sub getLoginId
{
    if ( isLoggedIn() ) {
        return cookie("login");
    } else {
        return 0;
    }
}

my $loginrec;

sub getLoginRec
{
    if ( isLoggedIn() ) {
        if ( !$loginrec ) {
            $loginrec = User::getRecord(getLoginId());
        }
        return $loginrec;
    }
    return undef;
}


sub getLoginName
{
    my $user = getLoginRec();
    return defined $user ? $user->{'name'} : undef;
}

sub getPassword
{
    my $user = getLoginRec();
    return defined $user ? $user->{'password'} : undef;
}

sub getLoginEmail
{
    my $user = getLoginRec();
    return defined $user ? "\"$$user{'name'}\" <$$user{'email'}>" : undef;
}

sub doLogout
{
    undef $loginrec;
}

sub doLogin
{
    $loginrec = User::getRecord(getLoginId());
}
    
sub isAdmin
{
    if ( !isLoggedIn() ) {
        return 0;
    }
    my $user = getLoginRec();
    return $user->{'admin'} eq "Y";
}
sub canSeeSalary
{
    if ( !isLoggedIn() ) {
        return 0;
    }
    my $user = getLoginRec();
    return $user->{'seesalary'} eq "Y";
}

1;
