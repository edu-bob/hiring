#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);

require "globals.pl";
use ParamTable;
use UserTable;

use Layout;
use Login;
use Database;
use Application;
use Utility;
use Audit;

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
    
    print Layout::doHeading({-title=>"Create a new user account"});
    
    print Layout::startForm, "\n";

    param("op", "go");
    print hidden({-name=>"op", -default=>"go"});

    print doEntryForm({-table=>\%::UserTable,
		       -hide=>['active','password','remind','admin']});

    print submit({-name=>"Submit"});

    print Layout::endForm, "\n";

    print Footer(), end_html;
}

## Process POST from the "enter new user" page

sub doGo
{
    print header;
    ConnectToDatabase;

    print Layout::doHeading({-title=>"Adding a new user"});

    # Check that at least the email is unique

    my $email = param('email');
    my @recs = Database::getRecordsMatch({-table=>\%::UserTable,
                                          -column=>"email",
                                          -value=>$email,
                                      });
    if ( scalar(@recs) > 0 ) {
        print p(b("A user with this e-mail aready exists:"));
        print Layout::doStaticValues({-table=>\%::UserTable, -record=>$recs[0]});
    } else {
        my $changes = new Changes(Converter::getConverterRef());
        Layout::doInsertFromParams({-table=>\%::UserTable,
                                    -changes=>$changes});
        auditUpdate($changes);
        print p("Addition successfully made");
        print $changes->listHTML();
    }
    print Layout::Footer(), end_html;
}

