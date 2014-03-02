# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Opening;


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

use OpeningTable;
use Department;

my $metaData = \%::OpeningTable;

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
    $cvtlist->{'opening_id'} = \&Opening::convert;
}

sub convert
{
    my $value = shift;
    my $rec = getRecordById({-table=>\%::OpeningTable, -id=>$value});
    return $rec->{'description'};
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
            my $opening = getRecordById({
                -table=>\%::OpeningTable,
                -id=>$id,
            });
            $cache{$id} = $opening;
        } else {
            Database::addQueryComment("cache hit Opening $id");
        }
        return $cache{$id};
    } else {
        return undef;
    }
}

sub openingLink
{
    my $argv = shift;
    argcvt($argv, ["id"], ["name"]);

    my $text;
    if ( $$argv{'name'} ) {
        $text = $$argv{'name'};
    } else {
        my $opening = getRecordById({
            -table=>\%::OpeningTable,
            -id=>$$argv{'id'},
            });
        $text = $$opening{'name'};
    }
    my $url = openingURL($$argv{'id'});
    return $url ? a({-href=>"$url"}, $text ? $text : "none") : $text;
}

sub openingURL
{
    my ($id) = (@_);
    my $rec = Opening::getRecord($id);
    return $rec->{'url'};
}

sub isActive
{
    my $id = shift;
    my $rec = Opening::getRecord($id);
    return $rec->{'status'} ne 'FILLED';
}

sub isActiveSQL
{
    return "opening.status != " . SQLQuote("FILLED");
}

sub menuLabel
{
    my $rec = shift;
    return $$rec{'description'} . " (" .
        Department::getAbbrev($$rec{'department_id'}) . ")";
}

sub getId
{
    my ($rec) = (@_);
    return $rec->{'id'};
}

1;
