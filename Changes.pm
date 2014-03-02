# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Changes;


use CGI qw(:standard *table *Tr *td);

=head1 NAME

changes - record DB changes for future use

=head1 SYNOPSIS

  Note: this is an OO interface

    use Changes;

    my $ch = new Changes;

    $ch->add({-table=>"table-name",
              -row=>"row-pk",
              -column=>"column-name",
              -secure=>"visibility type",
              -type="ADD|CHANGE|REMOVE",
              -old=>"old-value",
              -new=>"new-value",
              -user=>"who-did-this",
              -join_table=>"othertable",
              -join_id=>"othertable PK"
          });


=head1 DESCRIPTION

=over 4

=item changes::new

Creates a new blessed object for tracking changes.

=item changes::add

Adds a change record to a change object.

Required arguments are
    -table ....... which DB table changes
    -row ......... primary key of the table being changed
    -column ...... name of the column being changed
    -new ......... new value
    -user ......... who made the change

Optional arguments are
    -old ......... the old value
    -join_table .... if this entry pertains to some other table, this is the name of that table
    -join_id ....... the PK in that other table that this pertains to

=item changes::dump

=back

=cut


use 5.00;
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

## Default eported symbols
@EXPORT = qw();
## Optional exported symbols
@EXPORT_OK = qw();


use Argcvt;
use Database;
use Layout;
use Utility;

use User;
use AuditTable;


##
## new(\%converters);
##
## converters must be a hash that maps column names into strings that
## should be displayed in the HTML reports of changes
##
## %converters = {
##    "candidate_id" => &Candidate::converter,
##    "action_id" => &Action::converter,
## };
##

sub new
{
    my $self = {};
    @{$self->{'list'}} = ();
    $self->{'converters'} = $_[1];
    bless $self;
    return $self;
}


sub add
{
    my ($self, $argv) = (@_);
    
    my $err;
    if ( $err = argcvt($argv, ['table', 'row', 'column', 'user', 'type'],
                       ['old', 'new', 'creation','join_table','join_id','secure'])) {
        print "$err\n";
        return;
    }

    my $rec = {};
    $rec->{'user_id'} = $$argv{'user'};
    $rec->{'table'} = $$argv{'table'};
    $rec->{'row'} = $$argv{'row'};
    $rec->{'column'} = $$argv{'column'};
    if ( $argv->{'secure'} ) {
        $rec->{'secure'} = $argv->{'secure'};
    }
    if ( $$argv{'new'} ) {
        $rec->{'new'} = substr($$argv{'new'},0,100);
    }
    if ( $$argv{'old'} ) {
        $rec->{'old'} = substr($$argv{'old'},0,100);
    }

    if ( exists $$argv{'join_table'} && $$argv{'join_table'}  ) {
        $rec->{'join_table'} = $$argv{'join_table'};
    }
    if ( exists $$argv{'join_id'} && $$argv{'join_id'}  ) {
        $rec->{'join_id'} = $$argv{'join_id'};
    }

    $rec->{'type'} = $$argv{'type'};

    if ( exists $$argv{'creation'} ) {
        $rec->{'creation'} = $$argv{'creation'};
    }
    push @{$self->{'list'}},$rec;
}

sub size
{
    my $self = shift;
    return scalar(@{$self->{'list'}});
}

sub getList
{
    my $self = shift;
    return @{$self->{'list'}};
}

sub listAddHTML
{
    my $self = shift;
    my $argv = shift;
    argcvt($argv);
    my $result = "";
    $result .= start_table({-border=>"0", -cellpadding=>"2"});
    foreach my $rec ( @{$self->{'list'}} ) {
        if ( $rec->{'type'} ne "ADD" ) {
            next;
        }

        ## just skip all of these since we don't know who will see them

        if ( $rec->{'secure'} && $rec->{'secure'} eq 'seesalary' ) {
            next;
        }
        $result .= Tr(
                 td({-align=>"right"}, b($rec->{'column'} . ": ")),
                 td(i($rec->{'new'})));
    }
    $result .= end_table;
    return $result;
}

##
## listHTML - return a printable table of contents of a change record
##
## Optional named parameters:
##   table ... if given, this table prefix is omitted from the "field" column
##   user ... if given, this user's record is used for visibility
##   showskips ... if true, show a message to stdout about skipped columns (HACK)

sub listHTML
{
    my ($self, $argv) = (@_);
    argcvt($argv, [], ['table','user', 'showskips']);


    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
        $wday, $yday, $isdst) = localtime(time);
    my $dt = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                     1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds);

    my $rows = 0;
    my $result = "";
    $result .= start_table({-border=>"1", -cellpadding=>"4"}) . "\n";
    $result .= Tr(
                  td(b("When")), "\n",
                  td(b("Who")), "\n",
                  td(b("Type")), "\n",
                  td(b("Row")), "\n",
                  td(b("Field")), "\n",
                  td(b("Old Value")), "\n",
                  td(b("New Value")), "\n",
                  ) . "\n";
    foreach my $rec ( @{$self->{'list'}} ) {
        my $column;

        if ( $rec->{'column'} ) {
            if ( $rec->{'table'} ) {
                my $table = $$argv{'table'};
                if ( $table && $rec->{'table'} eq $table->{'table'} ) {
                    $column = $rec->{'column'};
                } else {
                    $column = "$rec->{'table'}.$rec->{'column'}";
                }
            } else {
                $column = "?.$rec->{'column'}";
            }
        } else {
            if ( $rec->{'table'} ) {
                $column = "$rec->{'table'}.?";
            } else {
                $column = "&nbsp;";
            }
        }

        ## This can be generalized but for now, just honor the seesalary visibility

        if ( $rec->{'secure'} && $rec->{'secure'} eq 'seesalary' ) {
            if ( !($$argv{'user'} && $$argv{'user'}->{'seesalary'} eq 'Y') ) {
                if ( $$argv{'showskips'} ) {
                    print "Not including data for \"$column\"<br/>\n";
                }
                next;
            }
        }

        $rows++;
        $result .= start_Tr() . "\n";
        $result .= td($rec->{'creation'}? $rec->{'creation'} : $dt) . "\n";
        my $user = User::getName($rec->{'user_id'});
        $result .= td($user) . "\n";
        $result .= td($rec->{'type'}) . "\n";
        $result .= td($rec->{'row'}) . "\n";
        $result .= td($column) . "\n";
      TYPE: {
          $rec->{'type'} eq "ADD" and do {
              $result .= td( "&nbsp;" ) . "\n";
              $result .= td( $self->cvtValue($rec->{'new'},
                                             $rec->{'table'},
                                             $rec->{'column'}) ) . "\n";
              last TYPE;
          };
          $rec->{'type'} eq "CHANGE" and do {
              $result .= td($self->cvtValue($rec->{'old'},
                                            $rec->{'table'},
                                            $rec->{'column'}) ) . "\n";
              $result .= td($self->cvtValue($rec->{'new'},
                                            $rec->{'table'},
                                            $rec->{'column'}) ) . "\n";
              last TYPE;
          };
          $rec->{'type'} eq "REMOVE" and do {
              $result .= td($rec->{'old'});
# there won't be anything to look up if the record was deleted
#              $result .= td( $self->cvtValue($rec->{'old'},
#                                             $rec->{'table'},
#                                             $rec->{'column'})  ) . "\n";
              $result .= td( "&nbsp;" ) . "\n";
              last TYPE;
          };
      };
        $result .= end_Tr() . "\n";
    }
    $result .= end_table . "\n";
    return $rows > 0 ? $result : undef;
}

sub cvtValue
{
    my ($self, $value, $dbtable, $dbcolumn) = (@_);
    my $newvalue;
    $newvalue = $value;
    my $displayString = Converter::convertToDisplayable({
        -value=>$value,
        -table=>$dbtable,
        -column=>$dbcolumn,
        });
    if ( defined $displayString ) {
        return $displayString;
    } else {
        return "NULL";
    }
}

sub updateAll
{
    my $self = shift;
    my $argv = shift;
    
    argcvt($argv);

    foreach my $rec ( @{$self->{'list'}} ) {
	exists $$argv{'user'} and $rec->{'user_id'} = $$argv{'user'};
	exists $$argv{'table'} and $rec->{'table'} = $$argv{'table'};
	exists $$argv{'row'} and $rec->{'row'} = $$argv{'row'};
	exists $$argv{'column'} and $rec->{'column'} = $$argv{'column'};
	exists $$argv{'secure'} and $rec->{'secure'} = $$argv{'secure'};
	exists $$argv{'new'} and $rec->{'new'} = substr($$argv{'new'},0,100);
	exists $$argv{'old'} and $rec->{'old'} = substr($$argv{'old'},0,100);
	exists $$argv{'join_table'} and $rec->{'join_table'} = $$argv{'join_table'};
	exists $$argv{'join_id'} and $rec->{'join_id'} = $$argv{'join_id'};
    }
}

##
## diff - update a changes record based on the differences of two records
##
## This code follows the pattern of Database::updateSimpleRecord in determing
## which columns changed.  In particular, if a column exists in the old record
## but not in the new one (or exists in the new but is undef) then the handling
## depends on the setting of the 'donulls' argument.
##    donulls == true .... log that the new column changed to NULL
##    donulls != true .... log nothing
##

sub diff
{
    my ($self, $argv) = (@_);
    argcvt($argv, ['table', 'row', 'old', 'new', 'user'], ['join_table', 'join_id', 'donulls']);

    my $table = $$argv{'table'};
    my $row = $$argv{'row'};
    my $old = $$argv{'old'};
    my $new = $$argv{'new'};
    my $donulls = $$argv{'donulls'};
    my $diffs = 0;
#    print h2("OLD"); Utility::ObjDump($old);
#    print h2("NEW"); Utility::ObjDump($new);

    foreach my $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'type'} eq "pk" ) {
            next;
        }
        if ( exists $$old{$tcol->{'column'}} && defined $$old{$tcol->{'column'}} ) {
            if ( exists $$new{$tcol->{'column'}} && defined $$new{$tcol->{'column'}} ) {
                if ( $$old{$tcol->{'column'}} ne $$new{$tcol->{'column'}} ) {

                    ##
                    ## Both the old and new values exist, and they are different.
                    ##

                    $self->add({-table=>$$table{'table'},
                                -row=>$row,
                                -type=>"CHANGE",
                                -column=>$tcol->{'column'},
                                -secure=>$tcol->{'secure'},
                                -user=>$$argv{'user'},
                                -old=>$$old{$tcol->{'column'}},
                                -new=>$$new{$tcol->{'column'}},
                                -join_table=>$$argv{'join_table'},
                                -join_id=>$$argv{'join_id'},
                            });
                    $diffs++;
                } else {

                    ##
                    ## The old value and new values both exist, and they are equal - do nothing
                    ##

                }
            } else {
                if ( defined $$old{$$tcol{'column'}} ) {
                    ##
                    ## The old value exists and is defined.
                    ## The new value does not exist
                    ##
                    if ( $donulls ) {
                        $self->add({-table=>$$table{'table'},
                                    -row=>$row,
                                    -column=>$tcol->{'column'},
                                    -secure=>$tcol->{'secure'},
                                    -type=>"CHANGE",
                                    -user=>$$argv{'user'},
                                    -old=>$$old{$tcol->{'column'}},
                                    -new=>undef,
                                    -join_table=>$$argv{'join_table'},
                                    -join_id=>$$argv{'join_id'},
                                });
                        $diffs++;
                    }
                } else {
                    ##
                    ## The old values exists and is undefined
                    ## The new value does not exist
                    ## Do nothing (is this correct???)
                    ##
#                    print p("Column $tcol->{'column'} no new value, old exists but is undefined");
                }
            } 
        } else { #no old value or exists and is undefined
            if ( exists $$new{$tcol->{'column'}} ) {

                ##
                ## No old value or is undefined
                ## New value exists
                ##

                if ( defined $$new{$tcol->{'column'}} ) {
                    $self->add({-table=>$$table{'table'},
                                -row=>$row,
                                -column=>$tcol->{'column'},
                                -user=>$$argv{'user'},
                                -secure=>$tcol->{'secure'},
                                -type=>"ADD",
#                                -old=>$$old{$tcol->{'column'}},
                                -new=>$$new{$tcol->{'column'}},
                                -join_table=>$$argv{'join_table'},
                                -join_id=>$$argv{'join_id'},
                            });
                    $diffs++;
                } else {

                    ## No old value or is undefined
                    ## New value is undefiuned

                    if ( !exists $$old{$tcol->{'column'}} && $donulls ) {

                        ## no old value
                        ## new value exists and is undefined

                        $self->add({-table=>$$table{'table'},
                                    -row=>$row,
                                    -column=>$tcol->{'column'},
                                    -secure=>$tcol->{'secure'},
                                    -user=>$$argv{'user'},
                                    -type=>"CHANGE",
                                    -old=>$$old{$tcol->{'column'}},
                                    -new=>$$new{$tcol->{'column'}}, # undef
                                    -join_table=>$$argv{'join_table'},
                                    -join_id=>$$argv{'join_id'},
                                });
                        $diffs++;
                    }
                }
            }
        }
    }
    
    return $diffs;
}


sub dump
{
    my $self = shift;
    print Utility::ObjDump($self);
}


sub merge
{
    my ($self, $other) = (@_);
    foreach my $rec ( @{$other->{'list'}} ) {
        push @{$self->{'list'}},$rec;
    }
}

1;
