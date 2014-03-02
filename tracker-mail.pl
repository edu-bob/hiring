#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


##
## Mail Catcher
##
## This script captures e-mail sent to the mail alias for the candidate tracker.
## If the e-mail is addressed "To:" a candidate in the tracker, the contents of the email
##    will be saved in the database as an uploaded document for that candidate.
##
## If this script canot decide what to do with the e-mail, it drops it into a 
## "lost mail" table in the database.
##

#use Database;
use Mail::Header;
use Data::Dumper;

#ConnectToDatabase();


open F,">/tmp/tracker-mail.txt" or die "$!: /tmp/tracker-mail.txt";

foreach my $e ( keys %ENV ) {
    print F "$e = $ENV{$e}\n";
}
print F "-------------\n";

my $h = new Mail::Header \*STDIN;

print F Dumper($h->header_hashref());
print F "-------------\n";

while ( <> ) {
    print F $_;
}
close F;
exit(0);

    
