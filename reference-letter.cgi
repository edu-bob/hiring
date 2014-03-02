#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img *p -nosticky);

require "globals.pl";
use FrontlinkTable;
use ParamTable;

use Layout;
use Login;
use Database;
use Application;
use Utility;

my $letter = "reference-check-questions.html";

my %map = (
	"CANDIDATES-FIRST-NAME" => "firstname",
	"CANDIDATES-NAME" => "name",
	"HIM/HER" => "himher",
	"HIS/HER" => "hisher",
	"YOUR-NAME" => "owner",
    "PERSON" => "person",
);

my $jscript =<<'END';
function dogender(f)
{
	i = f.gender.selectedIndex;
	option = f.gender.options[i].text;
	if ( option == "M" ) {
		f.hisher.value = "his";
		f.himher.value = "him";
	} else {
		f.hisher.value = "her";
		f.himher.value = "her";
	}
}
END

Application::Init();

if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "go" and do {
          doGo();
          last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
	print header;
	ConnectToDatabase();

	print Layout::doHeading({-title=>"Generate reference check e-mail",
				 -script=>$jscript});

        print start_p;
        print <<END;
This will generate a letter that you can copy and paste into an e-mail or some other document.
The letter will contain our reference check request message, including questions.
Note that this ONLY generates the letter,
it does not send it.
You must explicitly copy & paste it into an e-mail composition window.
You can then edit it as you see fit before sending it.
END
        print end_p;
	my %candidate;
	my ($firstname, $name, $owner);

	$name = "";
	$firstname = "";
	$owner = "";

	if ( isLoggedIn() ) {
		$owner = getLoginName();
	}

	if ( param("id") ) {
		%candidate = getRecordById({
			-table=>\%::CandidateTable,
			-id=>param("id"),
		});
		$name = $candidate{'name'};
		($firstname = $name) =~ s/ .*//;
	}

	print Layout::startForm({-name=>"form1"}), "\n";
	print hidden({-name=>"op", -default=>"go"});

	print start_table, "\n";

	print Tr(
			 td({-align=>"right"}, "Dear:"), "\n",
			 td(
				textfield({
					-name=>"person",
					-size=>"32"})), "\n",
			 ), "\n";
	print Tr(
			 td({-align=>"right"}, "Candidate's full name:"), "\n",
			 td(
				textfield({
					-name=>"name",
					-size=>"32",
					-default=>"$name"})), "\n",
			 ), "\n";
	print Tr(
			 td({-align=>"right"}, "Candidate's first name:"), "\n",
			 td(
				textfield({
					-name=>"firstname",
					-size=>"32",
					-default=>"$firstname"})),
			 );
	print Tr(
			 td({-align=>"right"}, "Gender:"), "\n",
			 td(popup_menu({-name=>"gender",
							-values=>['M', 'F'],
							-default=>'M',
							-onchange=>"dogender(document.form1);"})), "\n",
			 );
	print Tr(
			 td({-align=>"right"}, "Him or her: "), "\n",
			 td(popup_menu({-name=>"himher",
						   -values=>['him', 'her'],
						   -default=>'him'})), "\n",
			 );
	print Tr(
			 td({-align=>"right"}, "His or her: "), "\n",
			 td(popup_menu({-name=>"hisher",
						   -values=>['his', 'her'],
						   -default=>'his'})), "\n",
			 );
	print Tr(
			 td({-align=>"right"}, "Your name"), "\n",
			 td(
				textfield({
					-name=>"owner",
					-size=>"32",
					-default=>"$owner"})), "\n",
			 );
	print end_table, "\n";
	print submit({-name=>"Go"}), "\n";
	print Layout::endForm, "\n";

	print Footer(), end_html;
}

sub doGo
{
    print header;
    open F, "$letter" or do {
	print start_html, "\n";
	Utility::redError("Cannot open $letter: $!");
	print end_html;
	return;
    };
    my $sep = $/;
    undef $/;
    my $lines = <F>;
    foreach my $k ( keys %map ) {
	my $val = param($map{$k});
	$lines =~ s/$k/$val/g;
    }
    print $lines;
    close F;
}
