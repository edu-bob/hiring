# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Department;


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

my $metaData = \%::DepartmentTable;

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
##

my %cache;

sub getRecord
{
    my $id = shift;
    if ( $id ) {
        if ( !exists $cache{$id} ) {
            my $department = getRecordById({
                -table=>\%::DepartmentTable,
                -id=>$id,
            });
            $cache{$id} = $department;
        } else {
            Database::addQueryComment("cache hit Department $id");
        }
        return $cache{$id};
    } else {
        return undef;
    }
}

sub getAbbrev
{
    my $arg = shift;
    my $rec;
    if ( ref($arg) eq "HASH" ) {
        $rec = $arg;
    } else {
        $rec = Department::getRecord($arg);
    }
    if ( $rec ) {
        return $rec->{'abbrev'};
    } else {
        return "anonymous";
    }
}

##
## Note: this can either take a record ref or a PK id
##
 
sub getName
{
    my $arg = shift;
    my $rec;
    if ( ref($arg) eq "HASH" ) {
        $rec = $arg;
    } else {
        $rec = Department::getRecord($arg);
    }
    if ( $rec ) {
        return $rec->{'name'};
    } else {
        return "anonymous";
    }
}
                                                                                                                                                           

sub getAllDepartments
{
    return Database::getAllRecords({
        -table=>$metaData,
    });
}

1;
