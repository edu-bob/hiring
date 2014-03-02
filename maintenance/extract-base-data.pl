#!/usr/bin/perl


BEGIN {
    my $F = "DATABASE.pl";
    
    if ( -f "$F" ) {
	push @INC, ".";
    } elsif ( -f "../$F" ) {
	push @INC, "..";
    } else {
	die "ERROR: Cannot find $F in . or ..\n";
    }
    require "DATABASE.pl";
}
use Utility;
use Database;

Utility::setHTMLErrors(0);
ConnectToDatabase();

use Param;
print "--\n";
print "-- Parameter table\n";
print "--\n";
print "-- Edit the \"value\" column as needed\n";
print "--\n";
dumpTable(Param::getTable());

use Action;
print "--\n";
print "-- Next Action table\n";
print "--\n";
print "-- Edit the \"name\" and \"precedence\" columns as needed\n";
print "--\n";
dumpTable(Action::getTable());

use ActionCategory;
print "--\n";
print "-- Category table for Next Actions\n";
print "--\n";
print "-- Edit the columns as needed\n";
print "--\n";
dumpTable(ActionCategory::getTable());

exit(0);

sub dumpTable
{
    my $table = shift;
    my @recs = Database::getAllRecords({-table=>$table});
    my %widths = ();
    my @keys = ();
    foreach my $col ( @{$table->{'columns'}} ) {
	next if ( $col->{'column'} eq "creation" );
	push @keys, $col->{'column'};
    }
    foreach my $rec ( @recs ) {
	foreach my $column ( @keys ) {
	    next if ( $column eq "creation" || $column eq "u_creation" );
	    if ( length($column) > $width{$column} ) {
		$width{$column} = length($column);
	    }
	    if ( length($rec->{$column}) > $width{$column} ) {
		$width{$column} = length($rec->{$column});
	    }
	}
    }
    my $first = 1;
    foreach my $rec ( @recs ) {
	if ( $first ) {
	    $first = 0;
	    my $sep = "";
	    my $white = "";
	    foreach my $column ( @keys ) {
		next if ( $column eq "creation" || $column eq "u_creation" );
		print $sep, $white, "\"", $column, "\"";
		$white = " " x ($width{$column}-length($column)+1);
#		$sep = ",";
	    }
	    print "\n";
	    $sep = "";
	    $white = "";
	    foreach my $column ( @keys ) {
		next if ( $column eq "creation" || $column eq "u_creation" );
		print $sep, $white, "-" x ($width{$column}+2);
		$white = " ";
#		$sep = ",";
	    }
	    print "\n";
	}
	my $sep = "";
	my $white = "";
	foreach my $column ( @keys ) {
	    next if ( $column eq "creation" || $column eq "u_creation" );
	    print $sep, $white, "\"",$rec->{$column},"\"";
	    $white = " " x ($width{$column}-length($rec->{$column})+1);
#	    $sep = ",";
	}
	print "\n";
    }
}
