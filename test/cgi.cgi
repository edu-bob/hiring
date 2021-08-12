#!/usr/bin/perl
use CGI qw(:standard);

print header;
print start_html;

print h2("Candidate Tracker CGI Test");
print hr;
print p("SUCCESS!  Because you can read this, CGI script execution is set up correctly");
print hr;
print p("Once you have completed the INSTALL PERL CPAN MODULES step in the installation instructions, you can proceed to the next test.");
print p("Click here for the next test: ",
	a({-href=>"cpan.cgi"}, "Perl Module Test"));
print end_html;
