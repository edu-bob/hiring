package Argcvt;
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT      = qw(&argcvt);       # Symbols to autoexport (:DEFAULT tag)
@EXPORT_OK   = qw();              # Symbols to export on request

use CGI qw(:standard *p);

use Utility;

##
## argcvt - convert a hash list of named arguments and return that hash.
##
##  Caller:
##     doSomething({-foo=>"27", -bar=>"mumble}, ... )
##
##  Callee: (if hash list is ALWAYS expected to be the first argument)
##     sub doSomething
##     {
##         my $argv = shift;
##         argcvt($argv, ["required1", "required2"]);
##         ...
##         if ( $argv && $$argv{'foo'} ) {
##             ...
##         }
##
##  Callee:
##     sub doSomething
##     {
##         my $argv = $_[0];
##         if ( ref($argv) eq "HASH" ) {
##             argcvt($argv, ["required1", "required2"]);
##             shift;
##         }
##
##  Notes:
##    1) hash keys in the body of the callee should always be
##       all lowercase and without the dash
##    2) the dash on the actual arguments is optional
##

sub argcvt(@)
{
    my ($argv, $required, $optional) = (@_);

	my %tmp;

    foreach my $i ( keys %$argv ) {
		$tmp{$i} = $$argv{$i};
        if ( $i =~ /^-/ ) {
            my $newi = $i;
            $newi =~ s/^-//;
            $tmp{$newi} = $$argv{$i};
        }
    }
    foreach my $i ( keys %$argv ) {
        if ( $i ne lc($i) ) {
            my $newi = lc($i);
            $tmp{$newi} = $$argv{$i};
        }
    }
    my ($pack1, $file1, $line1, $subname1, $hasargs1, $wantarray1) = caller(1);
    my ($pack0, $file0, $line0, $subname0, $hasargs0, $wantarray0) = caller(0);
    foreach my $i ( @$required ) {
        if ( !exists $tmp{$i} ) {
	    Utility::redError("\"-$i\" is required as a named parameter to $pack1::$subname1() called from $file1:$line1");
	      Argcvt::argdump($argv, $required, $optional);
	      return "ERROR";
	  }
    }
    
    if ( defined $optional ) {
	my %validarg;
	foreach my $i ( (@$required, @$optional) ) {
	    $validarg{$i} = 1;
	}
	foreach my $a ( keys %tmp ) {
	    if ( $a =~ /^[a-z0-9]*$/ ) {
		if ( !exists $validarg{$a} ) {
		    Utility::redError("\"-$a\" is neither required nor optional to $pack1::$subname1 called from $file1:$line1");
		    Argcvt::argdump($argv, $required, $optional);
		}
	    }
	}
    }
    foreach my $i ( keys %tmp ) {
	$$argv{$i} = $tmp{$i};
    }
    return 0;
}

sub argdump
{
    my ($argv, $required, $optional) = (@_);
    my ($pack, $file, $line, $subname, $hasargs, $wantarray) = caller(2);

	print "$pack::$subname({",br;
	foreach my $i ( keys %$argv ) {
		print "&nbsp;&nbsp;&nbsp;&nbsp;", $i, "=>", $$argv{$i}, ",", br;
	}
	print "});";
#	print Utility::ObjDump($argv);

}


1;
