# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Param;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
             );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use ParamTable;

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;
use User;

my $metaData = \%::ParamTable;

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


##
## Caching routines
## In this component, unlike the other managers, the
## cache is managed by the 'name' column not the 'id' column
##

my %cache;


##
## getValueByName - return the value associated with a parameter
##
sub getValueByName
{
    my $name = shift;
    if ( !exists $cache{$name} ) {
        my @recs = getRecordsMatch({
            -table=>\%::ParamTable,
            -column=>"name",
            -value=>$name,
        });
        $cache{$name} = $recs[0];
    } else {
        Database::addQueryComment("cache hit Param $name");
    }
    return $cache{$name};
}

##
## load the in-memory cache with all of the parameters from the database
##
## This is used at start-up time since many of these will be fetched throughout
## the processing of the request.
##

sub loadCache
{
    my @records = Database::getAllRecords({-table=>Param::getTable()});
    foreach my $rec ( @records ) {
        $cache{$rec->{'name'}} = $rec->{'value'};
    }
}

sub setValue
{
    my ($name,$value) = (@_);
    my $query = "REPLACE param (name,value) VALUES (" .
        SQLQuote($name) . "," . SQLQuote($value) . ")";
    SQLSend($query);
}

1;
