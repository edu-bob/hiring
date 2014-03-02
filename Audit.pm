# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Audit;


=head1 NAME

audit - keep the audit trail

=head1 SYNOPSIS

  Note: this is a non-OO interface

    use Audit;

=head1 DESCRIPTION

=over 4

=back

=cut

use 5.00;   
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

@EXPORT = qw( &auditUpdate &auditGetRecords);
@EXPORT_OK = qw();

require "globals.pl";
use AuditTable;
use Argcvt;
use Database;
use Changes;
use Utility;

use CGI;

my $metaData = \%::AuditTable;

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


sub auditUpdate
{
    my $changes = shift;
    foreach my $ch ( $changes->getList() ) {
#        print Utility::ObjDump($ch);
        my $rec;
        $rec = {};
        $rec->{'user_id'} = $ch->{'user_id'};
        $rec->{'dbtable'} = $ch->{'table'};
        $rec->{'row'} = $ch->{'row'};
        $rec->{'dbcolumn'} = $ch->{'column'};
        $rec->{'join_table'} = $ch->{'join_table'};
        $rec->{'join_id'} = $ch->{'join_id'};
        $rec->{'secure'} = $ch->{'secure'};

        ## in case the add method didn't have a "type" specified:

        if ( !exists $ch->{'type'} ) {
            if ( exists $ch->{'old'} && exists $ch->{'new'} ) {
                $rec->{'type'} = "CHANGE";
                $rec->{'oldvalue'} = substr($ch->{'old'},0,100);
                $rec->{'newvalue'} = substr($ch->{'new'},0,100);
            } elsif ( !exists $ch->{'old'} ) {
                $rec->{'type'} = "ADD";
                $rec->{'newvalue'} = substr($ch->{'new'},0,100);
            } elsif ( !exists $ch->{'new'} ) {
                $rec->{'type'} = "DELETE";
                $rec->{'oldvalue'} = substr($ch->{'old'},0,100);
            }
        } else {
            $rec->{'type'} = $ch->{'type'};
            exists $ch->{'old'} and $rec->{'oldvalue'} = $ch->{'old'};
            exists $ch->{'new'} and $rec->{'newvalue'} = $ch->{'new'};
        }

        Database::writeSimpleRecord({-allownulls=>1, -table=>\%::AuditTable, -record=>$rec});
    }
}

##
## getRecords - read audit table records into a changes object
##
## Audit records are identified by a single table hash.  Though the changes object
## can hold entries for multiple tables, this function only supports getting entries
## for a single table and a singel row.
##
## Required named parameters:
##   table .... ref to table metadata hash
## Optional named parameters:
##   row ..... row value to select
##   converters ... a list of converters to attach to the changes record
##   join_table ... if specified, also add in records where the join_table field is used.
##   join_id ...... join row to match for join_table records
##


sub auditGetRecords
{
    my $argv = shift;
    argcvt($argv, ["table"], ["row", "join_table", "join_id", "converters"]);
    my $table = $$argv{'table'};

    my $where = "( dbtable = " . SQLQuote($table->{'table'});

    if ( defined $$argv{'row'} ) {
        $where .= " AND row = " . SQLQuote($$argv{'row'});
    }
    $where .= " )";

    if ( $$argv{'join_table'}) {
        $where .= " OR ( join_table = " . SQLQuote($$argv{'join_table'}) .
            " AND join_id = " . SQLQuote($$argv{'join_id'}) . " ) ";
    }

    my @records = getRecordsWhere({-table=>\%::AuditTable,
                                   -where=>$where,
                                   -dojoin=>0});

    my $changes = new Changes($$argv{'converters'});

    foreach my $rec ( @records ) {
        $changes->add({-table=>$$rec{'dbtable'},
                       -row=>$$rec{'row'},
                       -column=>$$rec{'dbcolumn'},
                       -secure=>$rec->{'secure'},
                       -type=>$$rec{'type'},
                       -user=>$$rec{'user_id'},
                       -new=>$$rec{'newvalue'},
                       -old=>$$rec{'oldvalue'},
                       -creation=>$$rec{'creation'},
                   });
    }
#    print Utility::ObjDump($changes);
    return $changes;
}


1;
