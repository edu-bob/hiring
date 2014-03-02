#!/usr/bin/perl
use CGI qw(:standard);
use Utility;

print header;
print start_html;

foreach my $i ( keys %::ENV ){
	print  "$i = $::ENV{$i}", br;
}

print h2("root URL");
print Utility::rootURL();

print end_html;
