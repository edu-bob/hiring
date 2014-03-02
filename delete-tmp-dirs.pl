#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use Data::Dumper;
use File::Path;

require "globals.pl";
use TempDirTable;

use Database;

ConnectToDatabase();

my $where = "UNIX_TIMESTAMP()-UNIX_TIMESTAMP(creation) > 3600";

my @dirs = getRecordsWhere({-table=>\%::TempDirTable,
						-where=>$where});

foreach my $rec ( @dirs ) {
	rmtree($$rec{'name'}, 1, 0);
	my $query = "delete from temp_dir where id = " . SQLQuote($$rec{'name'});
	print "Deleting entry from the database.\n";
	SQLSend($query);
}

