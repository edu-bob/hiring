#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use Getopt::Std;
use Data::Dumper;
use Mail::Mailer;

require "globals.pl";

use CategoryCountTable;

use Database;

my %opts;
getopts('c', \%opts);

if ( $opts{'c'} ) {
	doCounts();
}

exit(0);

sub doCounts
{
	ConnectToDatabase();

	my %ac_map = makeMap(\%::ActionCategoryTable,"name","id");
	my $query = "select count(*),action_category.name from candidate,action,action_category where candidate.status in ('NEW','ACTIVE') and  action_id = action.id and action.category_id = action_category.id  group by action.category_id order by action_category.precedence";

	SQLSend($query);
	my ($count,$category);
	my %catcounts;
	while ( ($count,$category) = SQLFetchData() ) {
		$catcounts{$category} = $count;
	}

	SQLSend("select count(*) from candidate where status = 'HIRED'");
	$catcounts{'hired'} += SQLFetchOneColumn();
	SQLSend("select count(*) from candidate where status = 'REJECTED'");
	$catcounts{'rejected'} += SQLFetchOneColumn();


	print Dumper(\%catcounts);

	SQLSend("SELECT NOW()");
	my $dt = SQLFetchOneColumn();


	print "$dt\n";
}
