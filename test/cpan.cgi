#!/usr/bin/perl

use CGI qw(:standard *p *h2 *h3);

my $html = 0;
if ( exists $ENV{'REQUEST_URI'} ) {
    $html = 1;
}

if ( -f "candidates.cgi" ) {
    chdir("test");
} elsif ( ! -f "../candidates.cgi" ) {
    print "This must be run from the document root for the candidate tracker or from 'test'\n";
    exit(1);
}


print header if $html;
print start_html if $html;

print h1("Candidate tracker - Perl module test"), hr if $html;
print start_p if $html;
print "Testing to see if all of the necessary Perl modules exist\n";
print end_p if $html;

my $errors = 0;
opendir(D, "..") or die "Cannot open ..: $!\n";
my @files = grep { /\.(cgi|pm)$/ } readdir D;
closedir D;

chdir("..");

my %packages;
foreach my $f ( @files ) {
    open F, $f or do {
	print "ERROR $f: $!\n";
	next;
    };
    while ( <F> ) {
	my @fields = split /\s+/;
	if ( $fields[0] eq "use" ) {
	    my $pkg = $fields[1];
	    $pkg =~ s/;$//;
	    $packages{$pkg}++;
	}
    }
    close F;
}
foreach my $k ( keys %packages ) {
    eval "require $k";
    if ( $@ ) {
	if ( $errors == 0 ) {
	    print start_h2 if $html;
	    print "Errors\n";
	    print end_h2 if $html;
	}
	print start_h3 if $html;
	print "$k\n";
	print end_h3 if $html;
	print "<pre>" if $html;
	print $@, "\n";
	print "</pre>" if $html;
	$errors++;
    }
}
if ( $errors == 0 ) {
    print start_p if $html;
    print "Congratulations!  There were no Perl module loading errors.\n";
    print end_p if $html;
    if ( $html ) {
	print hr; 
	print p("If you haven't set up the mysql database, go no further with this test until you have the database set up.  Otherwise, click here for the next test:", a({-href=>"mysql.cgi"}, "mysql test"));
    }
} else {
    print hr if $html;
    print start_p if $html;
    print "Please review the errors above and resolve them before proceeding.\n";
    print end_p if $html;
}

print end_html if $html;

