# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Document;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
             );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

require "globals.pl";

use URI::Escape;

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;

use DocumentTable;

my $metaData = \%::DocumentTable;

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
    $cvtlist->{'document'} = \&Document::convert;
}

sub convert
{
    my $value = shift;
    my @recs = getRecordsMatch({-table=>\%::DocumentTable, -column=>"id", -value=>$value});
    if ( scalar @recs == 0 ) {
        return "#$value (deleted)";
    } else {
        return Document::link({
            -id=>$value,
        });
    }
}

sub link
{
    my $argv = shift;
    argcvt($argv, ["id"], ["name"]);

    my $text;
    if ( $$argv{'name'} ) {
        $text = $$argv{'name'};
    } else {
        my $doc = Document::getRecord($$argv{'id'});
        $text = $doc->{'contents'};
    }
    my $url = fullURL("document.cgi?id=$$argv{'id'}");
    return a({-href=>$url}, $text);
}

##
## Caching routines
##

my %cache;

sub getName
{
    my $id = shift;
    my $rec = Document::getRecord($id);
    return $rec->{'contents'};
}


sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $document = getRecordById({
            -table=>\%::DocumentTable,
            -id=>$id,
        });
        $cache{$id} = $document;
    } else {
        Database::addQueryComment("cache hit Document $id");
    }
    return $cache{$id};
}




1;
