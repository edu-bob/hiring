# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Manager;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(-nosticky :standard *table *ol *ul *Tr *td escape *p);
use Layout;
use Database;
use Argcvt;
use Utility;
use Audit;
use Login;

require "globals.pl";
use Application;


##
## doManage - combines an add form with a edit/delete table
##

sub doManage
{
    my $table = shift;
    doMustLogin(self_url());
    
    print header;
    ConnectToDatabase();
    
    my $self_url = self_url();
    my $url = url();
    print doHeading({-title=>"Manage \"$table->{'heading'}\""}), "\n";

    print h2("Add to \"$table->{'heading'}\""), "\n";
    
    print Layout::startForm({-action=>url(), -status=>1}), "\n";
    print hidden({-name=>"table", -default=>"$table->{'table'}"}), "\n";
    if ( param("back" ) ) {
	print hidden({-name=>"back", -default=>param("back")});
    }
    print doEntryForm({-table=>$table});
    param("op", "addfinish");
    print hidden({-name=>"op", -default=>"addfinish"}), "\n";
    print submit({-name=>"Add"}), "\n";
    print Layout::endForm;
    
    print hr, h2("Edit/Delete \"$table->{'heading'}\""), "\n";
    print Layout::startForm({-action=>url()}), "\n";
    print hidden({-name=>"table", -default=>"$table->{'table'}"}), "\n";
    print doEditTable({-table=>$table});
    print Layout::endForm, "\n";
    print hr, p(a({-href=>"$url?op=audit;table=$table->{'table'}"}, "Show audit trail")), "\n";
    
    print Footer({-url=>"$self_url"});			 
    print end_html, "\n";
}

##
## doAdd - op == "add" - for special links from elsewhere
##

sub doAdd
{
    doMustLogin(self_url());

    print header;
    ConnectToDatabase();

    my $self_url = self_url();
    my $table = shift;

    print doHeading({-title=>"Add \"$table->{'heading'}\""});

    print Layout::startForm({-action=>url(), -status=>1}), "\n";
    my $changes = new Changes;
#    print p(self_url());
    print doEntryForm({-table=>$table});
    auditUpdate($changes);
    param("op", "addfinish");
    print hidden({-name=>"op",    -default=>"addfinish"}), "\n";
    print hidden({-name=>"table", -default=>"$table->{'table'}"});
    if ( param("back" ) ) {
	print hidden({-name=>"back", -default=>param("back")});
    } else {
        my $url = url() . "?table=$table->{'table'};op=add";
        print hidden({-name=>"back", -default=>$url});
    }
        
    print submit({-name=>"Add"}), "\n";
    print Layout::endForm;

    print Footer({-url=>"$self_url"}), end_html;
}

##
## doAddFinish - op == addfinish - called from "add" button
##

sub doAddFinish
{
    doMustLogin(self_url());

    my $argv = shift;
    argcvt($argv, ['table'], ['back']);
    my $table = $$argv{'table'};

    my $back = $$argv{'back'};

    print header;
    ConnectToDatabase();

    my $self_url = self_url();

    my $url;
    if ( $back ) {
        $url = $back;
    } else {
        $url = url() . "?table=$table->{'table'}";
    }
    print doHeading({-title=>"Add \"$table->{'heading'}\"",
                     -head=>meta({-http_equiv=>"Refresh",
                                  -content=>"$::REFRESH;URL=$url"})});

    my $changes = new Changes;
    my $insertid = doInsertFromParams({-table=>$table,
				       -changes=>$changes});
    if ( defined $insertid ) {
        auditUpdate($changes);
        if ( exists $$table{'postadddisplay'} ) {
            &{$$table{'postadddisplay'}}($insertid, $changes);
        } else {
            print p("Entry #$insertid added.");
            print $changes->listAddHTML();
        }
    } else {
        print p("Errors detected, nothing saved.");
    }
    print p(a({-href=>"$url"}, "Reloading...")), Footer({-url=>"$self_url"}), end_html, "\n";
}


##
## doEditDelete - one of Edit or Delete buttons hit
##

sub doEditDelete
{
    my $table = shift;

    my @params = param();
    foreach my $p ( @params ) {
      SWITCH:
        {
            $p =~ /^edit[0-9]+/ and do {
                $p =~ s/^edit//;
                doEditInternal($table, $p);
                last SWITCH;
            };
            $p =~ /^delete[0-9]+/ and do {
                $p =~ s/^delete//;
                doDelete($table, $p);
                last SWITCH;
            };
        };
    }
}

##
## doEditInternal - called from doEditDelete
##

sub doEditInternal
{
    Layout::doMustLogin(self_url());
    print header;
    ConnectToDatabase();

    my $self_url = self_url();
    my $table = shift;
    my $pk = shift;

    print doHeading({-title=>"Edit \"$table->{'heading'}\" #$pk"});
    my $record = getRecordById({-table=>$table, -id=>$pk});

    param("op", "editfinish");
    print Layout::startForm({-action=>url(), -status=>1}), "\n",
      hidden({-name=>"op", -default=>"editfinish"}), "\n";
    print hidden({-name=>"table", -default=>"$table->{'table'}"}), "\n";

    if ( param("reload") ) {
        print hidden({-name=>"reload", -default=>param("reload")});
    }

    print hidden({-name=>"pk", -default=>"$pk"});
    print doEditForm({-table=>$table, -record=>$record});
    print submit({-name=>"Update"}), "\n";
    print Layout::endForm;

    print Footer({-url=>"$self_url"}), end_html, "\n";
}

sub doEditFinish
{
    Layout::doMustLogin(self_url());

    print header;
    ConnectToDatabase();

    my $self_url = self_url();
    my $table = shift;

    my $pk = param("pk");

    my $reload;
    if ( param("reload") ) {
        $reload = param("reload");
    } else {
        $reload = url() . "?table=$table->{'table'}";
    }

    print doHeading({-title=>"Finish Edit \"$table->{'heading'}\"",
                     -head=>meta({-http_equiv=>"Refresh",-content=>"$::REFRESH;URL=$reload"})});

    my $rec = getRecordById({-table=>$table, -id=>$pk});

    ## Update the DB from the FORM data, capture changes in a change record
    my $changes = new Changes;
    doUpdateFromParams({-table=>$table,
                        -record=>$rec,
                        -changes=>$changes});
    Audit::auditUpdate($changes);

    print $changes->listHTML();
    print p(a({-href=>$reload}, "Reloading..."));
    print Footer({-url=>"$self_url"}), end_html, "\n";
}


sub doDelete
{
    Layout::doMustLogin(self_url());

    print header;
    ConnectToDatabase();

    my $self_url = self_url();
    my $table = shift;

    my $pk = shift;

    my $reload;
    if ( param("reload") ) {
        $reload = param("reload");
    } else {
        $reload = url() . "?table=$table->{'table'}";
    }

    print doHeading({-title=>"Delete \"$table->{'heading'}\"",
                     -head=>meta({-http_equiv=>"Refresh",-content=>"$::REFRESH;URL=$reload"})});
    my $query = "DELETE from $table->{'table'} WHERE id = " . SQLQuote($pk);
    SQLSend($query);
    print p("Entry deleted");

    if ( exists $table->{'postdelete'} ) {
        &{$table->{'postdelete'}}($pk);
    }
    print p(a({-href=>$reload}, "Reloading..."));
    print Footer({-url=>"$self_url"}), end_html, "\n";
}


##
## doDisplay
##

sub doDisplay
{
    print header;
    ConnectToDatabase();

    my $self_url = self_url();
    my $table = shift;
    my $id = param("id");

    my $record = getRecordById({-table=>$table, -id=>$id});
    print doHeading({-title=>"View from $table->{'heading'}: " . ( $table->{'label'} ? $$record{$$table{'label'}} : "#$id")});

    print doStaticValues({-table=>$table,-record=>$record});

    print Footer({-url=>"$self_url"}), end_html, "\n";
}

sub doList
{
    my $table = shift;

    print header;
    ConnectToDatabase();
    print doHeading({
        -title=>"\"" . ucfirst($table->{'table'}) . "\" Entries",
    });
    my @recs = Database::getAllRecords({-table=>$table});
    
    # Table of contents

    my $columns = 3;
    my $rows = int((scalar(@recs)+$columns-1)/$columns);
    print start_table;
    for ( my $i=0 ; $i<$rows ; $i++ ) {
        print start_Tr, "\n";
        for ( my $j=0 ; $j<$columns ; $j++ ) {
            my $ele = $j*$rows+$i;
            if ( $ele < scalar(@recs) ) {
                my $mark = $recs[$ele]->{$table->{'label'}};
                $mark =~ s/[ .,-]/_/g;
                my $active = 1;
                if ( exists $table->{'filters'} ) {
                    if ( ref($table->{'filters'}) eq "ARRAY" ) {
                        foreach my $frec ( @{$table->{'filters'}} ) {
                            if ( exists $frec->{'active'} &&
                                 !&{$frec->{'active'}}($recs[$ele]->{'id'}) ) {
                                $active = 0;
                            }
                        }
                    } else {
                        if ( exists $table->{'filters'}->{'active'} &&
                             !&{$table->{'filters'}->{'active'}}($recs[$ele]->{'id'}) ) {
                            $active = 0;
                        }
                    }
                }
                if ( $active ) {
                    print td(a({-href=>"#$mark"}, $recs[$ele]->{$table->{'label'}}));
                } else {
                    print td("<strike>", a({-href=>"#$mark"}, $recs[$ele]->{$table->{'label'}}),"</strike>");
                }
            } else {
                print td("&nbsp;");
            }
            print td({-width=>"24"});
        }
        print end_Tr, "\n";
    }
    print end_table;


    foreach my $rec ( @recs ) {
        my $mark = $rec->{$table->{'label'}};
        $mark =~ s/[ .,-]/_/g;
        print h2(a({-name=>$mark}, $rec->{$table->{'label'}}));
        print Layout::doStaticValues({
            -table=>$table,
            -record=>$rec,
            -skipempty=>1,
            -hide=>['creation'],
        });
        if ( isAdmin() ) {
            print a({-href=>"manage.cgi?table=$$table{'table'};op=edit;id=$$rec{'id'}"}, "Edit");
        }
    }

}

1;
