#!/usr/bin/perl -w
use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img *p -nosticky);

BEGIN {push @INC, "..";}

require "globals.pl";
use FrontlinkTable;
use ParamTable;

use Layout;
use Login;
use Database;
use Application;
use Utility;

print header;
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
	ConnectToDatabase();

	print Layout::doHeading({-title=>"Application Inspection",
                             });

        print h2("Application Converters");
        print start_ul, "\n";
        foreach my $k ( keys %{Converter::getConverterRef()} ) {
            print li($k), "\n";
        }
        print end_ul, "\n";
	print Footer(), end_html;
}

sub doGo
{
}
