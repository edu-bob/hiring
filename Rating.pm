# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Rating;


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

use RatingTable;

my $metaData = \%::RatingTable;

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
    $cvtlist->{'rating.rating'} = \&Rating::convert_rating;
    $cvtlist->{'candidate.rating'} = \&Rating::convert_candidate;
}

sub convert_rating
{
    my $value = shift;
    return "$value";
}
sub convert_candidate
{
    my $value = shift;
    my @recs = getRecordsMatch({-table=>\%::RatingTable, -column=>"id", -value=>$value});
    if ( scalar @recs == 0 ) {
        return "#$value (deleted)";
    } else {
        my $comment_length = 25;
        my $str = sprintf("%.2f", $recs[0]->{'rating'});
        
        if ( length($recs[0]->{'comment'}) > $comment_length ) {
            $str .= " (" . substr($recs[0]->{'comment'}, 0, $comment_length) . " . . .)";
        } else {
            $str .=  " ($recs[0]->{'comment'})";
        }
        return $str;
    }
}

##
## Caching routines
##

my %cache;

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $Rating = getRecordById({
            -table=>\%::RatingTable,
            -id=>$id,
        });
        $cache{$id} = $Rating;
    } else {
        Database::addQueryComment("cache hit Rating $id");
    }
    return $cache{$id};
}

sub invalidate
{
    my $id = shift;
    delete($cache{$id});
}

1;
