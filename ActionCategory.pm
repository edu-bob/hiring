# -*- Mode: perl; indent-tabs-mode: nil -*-

# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package ActionCategory;


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

use ActionCategoryTable;

my $metaData = \%::ActionCategoryTable;

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
    $cvtlist->{'category_id'} = \&ActionCategory::convert;
    $cvtlist->{'actioncategory_id'} = \&ActionCategory::convert;
}

sub convert
{
    my $value = shift;
    return "(null)" if ( !$value );
    my $rec = ActionCategory::getRecord($value);
    return defined $rec ? $rec->{'name'} : "(null)";
}


##
## Caching routines
##

my %cache;

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $actioncategory = getRecordById({
            -table=>\%::ActionCategoryTable,
            -id=>$id,
        });
        $cache{$id} = $actioncategory;
    } else {
        Database::addQueryComment("cache hit ActionCategory $id");
    }
    return $cache{$id};
}

1;
