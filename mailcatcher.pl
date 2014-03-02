#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


#use Database;
use Mail::Header;
use Data::Dumper;

#ConnectToDatabase();


open F,">/tmp/mail.txt" or die "$!: /tmp/mail.txt";

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

    
