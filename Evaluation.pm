# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Evaluation;


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
use Opening;

use EvaluationTable;

my $metaData = \%::EvaluationTable;

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
    $cvtlist->{'document'} = \&Evaluation::convert;
}

sub convert
{
    my $value = shift;
    my @recs = getRecordsMatch({-table=>\%::EvaluationTable, -column=>"id", -value=>$value});
    if ( scalar @recs == 0 ) {
        return "#$value (deleted)";
    } else {
        return Evaluation::link({
            -id=>$value,
        });
    }
}



##
## Caching routines
##

my %cache;

sub getName
{
    my $id = shift;
    my $rec = Evaluation::getRecord($id);
    return $rec->{'contents'};
}


sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $document = getRecordById({
            -table=>\%::EvaluationTable,
            -id=>$id,
        });
        $cache{$id} = $document;
    } else {
        Database::addQueryComment("cache hit Evaluation $id");
    }
    return $cache{$id};
}




##
## generateCCJavaScript - generate the JavaScript that maps the opening_id to
## the list of user_id values on the CC list
##

sub generateCCJavaScript
{

    my $recs = Database::getRecordsWhere({
        -table => $metaData,
                                       });
    my @opening_ids = map { $_->{'opening_id'} } @$recs;
    my @cc;
    foreach my $opening_id ( @opening_ids ) {
        $cc[$opening_id] = [ map { $_->{'user_id'} }
                             grep {$_->{'opening_id'}==$opening_id} @$recs ];
    }

    my @users;
    foreach my $user ( User::getAll() ) {
        $users[$user->{'id'}] = $user->{'name'};
    }

    my $js = '';
    use JSON;

    $js = join('', map { $_ . "\n" } (
                   "var cc = new Array();",
                   "cc = " . encode_json(\@cc) . ';',
                   'users = new Array();',
                   'users = ' . encode_json(\@users) . ';',
    ));
    return $js;
}



1;
