# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Action;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;

use ActionTable;

my $metaData = \%::ActionTable;

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


##

sub addConverter {
    my $cvtlist = shift;
    $cvtlist->{'action_id'} = \&Action::convert;
}

sub convert
{
    my $value = shift;
    if ( $value ) {
        my $rec = getRecordById({-table=>\%::ActionTable, -id=>$value});
        if ( $rec ) {
            return $rec->{'action'};
        } else {
            return "#$value (deleted)";
        }
    } else {
        return defined $value ? "--NONE--" : undef;
    }
}

1;
