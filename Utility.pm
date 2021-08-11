# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


##
## Utility routines

package Utility;


use 5.00;   
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

@EXPORT = qw(
    preHTMLAbort
);

@EXPORT_OK = qw();

use CGI qw(:standard *p);
use Data::Dumper;

require "globals.pl";

##
##  true => enable display of errors in HTML
## false => enable display of errors in TEXT
##

sub setHTMLErrors
{
    my $arg = shift;
    $::TEXT_ERRORS = !$arg;
}

##
## for debugging, disables all insert and updates to the database
##

sub setSQLNoWrite
{
    $::SQL_NOWRITE = shift;
}

##
## Formats and returns an error message in red (HTML only)
##

sub errorMessage
{
    return p(font({-color=>"#ff0000"}, "ERROR: ", @_));
}

sub preHTMLAbort
{
    print header;
    print start_html;
    print Utility::errorMessage(@_);
    print p("Aborting.");
    print end_html;
    exit 0;
}

##
## Formats and prints an error and a traceback
##

sub redError
{
    my $str = shift;
    if ( $::TEXT_ERRORS ) {
        print "$str at\n";
    } else {
        print start_p, b(font({-color=>"#ff0000"},"$str at ")), br;
    }
    for ( my $i=1; $i<6 ; $i++ ) {
        my ($pack, $file, $line, $subname, $hasargs, $wantarray) = caller($i);
		if ( defined $subname ) {
                    if ( $::TEXT_ERRORS ) {
                        print "    " . $subname . "() called from $file:$line\n";
                    } else {
			print font({-color=>"#ff0000"},"&nbsp;&nbsp;&nbsp;&nbsp;" . $subname . "() called from $file:$line",br);
                    }
		}
    }
    if ( ! $::TEXT_ERRORS) {
        print end_p;
    }
}

##
## converts a text area to HTML-displayable text, escaping HTML characters
## and converting links
##

sub cvtTextarea
{
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;  # "
    $str =~ s{((?:https?|ftp|telnet)://(?:[\w-]+\.)?[\w-]+\.\S+)}{<A HREF="$1">$1</A>}g;
    $str =~ s/\n/<br>/sg;
    return $str;
}

sub cvtTextline
{
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;  # "
    $str =~ s{((?:https?|ftp|telnet)://(?:[\w-]+\.)?[\w-]+\.\S+)}{<A HREF="$1">$1</A>}g;
    $str =~ s/\n/&para;/sg;
    return $str;
}

##
## for debugging, dumps a Perl object into HTML
##

sub ObjDump
{
    print "<pre>", Dumper(@_), "</pre>";
}

##
## returns the current date & time in standard form (YYYY-MM-DD HH:MM:SS)

sub now
{
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
        $wday, $yday, $isdst) = localtime(time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                   1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds);
}

sub copyright
{
    my $copyright = <<EOF;
Copyright &copy; 2003-2006 Robert L. Brown.  All Rights Reserved.  Reproduction of this
document without explicit written permission is prohibited.
EOF
    return $copyright;
}

##
## rootURL - generates (or guesses) the URL of the home page and
##           returns it.
##
## e.g. returns / or /hiring or /dir1/dir1/hiring
##
sub rootURL
{
    my $url;

    if ( exists $::ENV{'REQUEST_URI'} ) {
        ($url = $::ENV{'REQUEST_URI'}) =~ s(/[^/]*$)();
    } elsif ( exists $::ENV{'SCRIPT_NAME'} ) {
        ($url = $::ENV{'SCRIPT_NAME'}) =~ s(/[^/]*$)();
    } else {
        $url = "";
    }
    if ( length($url) == 0 ) {
        $url = "/";
    }
    return $url;
}

1;

