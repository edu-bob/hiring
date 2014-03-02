#!/usr/bin/perl
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard -nosticky *table *Tr);

require "globals.pl";

use Application;
use Login;
use Audit;
use Changes;
use Database;
use Layout;
use Manager;
use Utility;

require "tables.pl";


Application::Init();

my $thetable = 0;

##
## "check" is a special op that compares the metadata tables within this program
## to the schema in the database and reports on any misalignments
##
if ( defined param("op") && param("op") eq "check" ) {
    doCheck();
    exit(0);
}

##
## for all other ops, the "table" parameter must be specified.  It states
## which DB table is to be operated on.
##
## Find the metadata hash for the "table" parameter; bail if not found
##

my $table = param("table");
if ( !defined $table ) {
    print header,start_html({-style=>{-src=>"style.css"}});;
    print p(b("Error, no table defined in manage.cgi"));
    print end_html;
    exit(0);
}
foreach my $t ( @::Tables ) {
    if ( $table eq $t->{'table'} ) {
        $thetable = $t;
        last;
    }
}

if ( !defined $thetable || ! $thetable ) {
    print header,start_html({-style=>{-src=>"style.css"}});
    print p(b("Error, bad table \"$table\" defined in manage.cgi"));
    print end_html;
    exit(0);
}

##
## op:
##   add ......... presents only the "add entry" section (not used)
##   addfinish ... processes the POST from the "add entry" form
##   edit ........ presents the "edit entry" form
##   editdelete .. processes the POST from one of the EDIT or DELETE buttons in
##                 the master list table
##  editfinish ... processes the POST from the "edit entry" form
##  audit ........ displays the audit trail for the given table
##
## if op is undef, then the add table and the master edit/delete table is presented
##

if ( defined param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "add" and do {
          Manager::doAdd($thetable);
          last SWITCH;
      };
      $op eq "addfinish" and do {
          Manager::doAddFinish({-table=>$thetable, -back=>param("back")});
          last SWITCH;
      };
      $op eq "edit" and do {
          doEdit($thetable);
          last SWITCH;
      };
      $op eq "editdelete" and do {
          Manager::doEditDelete($thetable);
          last SWITCH;
      };
      $op eq "editfinish" and do {
          Manager::doEditFinish($thetable);
          last SWITCH;
      };
      $op eq "audit" and do {
          doAudit($thetable);
          last SWITCH;
      };
      $op eq "display" and do {
          Manager::doDisplay($thetable);
          last SWITCH;
      };
      $op eq "list" and do {
          Manager::doList($thetable);
          last SWITCH;
      };

  };
} else {
    Manager::doManage($thetable);
}
exit(0);



sub doEdit
{
    my $table = shift;
    my $id = param("id");
    Manager::doEditInternal($table, $id);
}


##
## check meta data against the tables in the DB
##

sub doCheck
{
    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Compare metadata to DB"});
    
    my @dbtables = GetTableNames();
    my %db;
    foreach my $t ( @dbtables ) {
        SQLSend("SHOW COLUMNS FROM $t");
        my $columns;
        my @fields;
        while ( @fields = SQLFetchData() ) {
            my $colattr;
            $colattr = {};
            $colattr->{'column'} = $fields[0];
            $colattr->{'type'} = $fields[1];
            $colattr->{'null'} = $fields[2];
            $colattr->{'key'} = $fields[3];
            $colattr->{'default'} = $fields[4];
            $colattr->{'extra'} = $fields[5];
            $colattr->{'privileges'} = $fields[6];
            $columns->{$fields[0]} = $colattr;
        }
        $db{$t} = $columns;
    }
#	print Utility::ObjDump(\%db);
    
    foreach my $t ( @::Tables  ) {
		print h2($t->{'table'});
		if ( !defined $db{$t->{'table'}} ) {
			print p(b(font({-color=>"#ff0000"},"Table $t->{'table'} exists in meta data but not the database")));
			next;
		}
		my $errors = 0;
		my $dbtab = $db{$t->{'table'}};
		print start_table, Tr(
					   td(b("Column")).
					   td(b("Metadata type")),
					   td(b("DB Type")),
					   );
		foreach my $tcol ( @{$t->{'columns'}} ) {
			if ( !exists $$tcol{'type'} ) {
				print Tr(td({-colspan=>"3"},
							p(b(font({-color=>"#ff0000"},
									 "Column $tcol->{'column'} does not have a data type")))));
				$errors++;
			}
			if ( !exists $dbtab->{$tcol->{'column'}} ) {
				print Tr(td({-colspan=>"3"},
							p(b(font({-color=>"#ff0000"},
									 "Column $tcol->{'column'} exists in metadata but not in the DB")))));
				$errors++;
			} else {
				print Tr(
						 td($tcol->{'column'}),
						 td($tcol->{'type'}),
						 td($dbtab->{$tcol->{'column'}}->{'type'}),
						 );
				my $attr = $dbtab->{$tcol->{'column'}};
				$attr->{'db'} = 1;
			}
		}
		print end_table;
		foreach my $k ( keys %$dbtab ) {
			my $attr = $dbtab->{$k};
			if ( ! exists $attr->{'db'} ) {
				print p(b(font({-color=>"#ff0000"},"Column $k exists in the DB but not in the metadata")));
				$errors++;
			}
		}
		if ( $errors==0 ) {
			print p("Database and meta data agree exactly.");
		}
	}
    print Utility::ObjDump(\%db);
    print end_html;
}


sub doAudit
{
    doMustLogin(self_url());

    my $table = shift;

    print header;
    ConnectToDatabase();
    print doHeading({-title=>"Changes to \"$table->{'heading'}\""}), "\n";

    my $candidate_id = param("id"); # candidate_id
    my $self_url = self_url();

	my $changes = auditGetRecords({-table=>$table});
	print $changes->listHTML({-table=>$table});

    my $backurl = url() . "?table=$table->{'table'}";
    print p(a({-href=>$backurl}, "Back to \"$table->{'heading'}\" edit page"));
    print Footer({-url=>"$self_url"}), end_html;
    print end_html;
}
