# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Recruiter;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 &recruiterLink
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use RecruiterTable;

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;
use User;

my $metaData = \%::RecruiterTable;

my $Subject = undef;# put in as the e-mail subject if defined

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


sub addConverter {
    my $cvtlist = shift;
    $cvtlist->{'recruiter_id'} = \&Recruiter::convert;
}

sub convert
{
    my $value = shift;
    if ( $value ) {
        my @recs = getRecordsMatch({-table=>\%::RecruiterTable, -column=>"id", -value=>$value});
        if ( scalar @recs == 0 ) {
            return "#$value (deleted)";
        } else {
            return Recruiter::recruiterLink({-id=>$value,
                                             -name=>$recs[0]->{'name'}});
        }
    } else {
        return "NULL";
    }
}


sub recruiterLink
{
    my $argv = shift;
    argcvt($argv, ["id"], ["name", 'agency']);

    my $text;
    if ( $$argv{'name'} ) {
        $text = $$argv{'name'};
        if ( $$argv{'agency'} ) {
            $text .= " ($$argv{'agency'})";
        }
    } else {
        my $recruiter = Recruiter::getRecord($$argv{'id'});
        $text = $$recruiter{'name'};
        if ( $$recruiter{'agency'} ) {
            $text .= " ($$recruiter{'agency'})";
        }
    }
    my $url = recruiterURL($$argv{'id'});
    return a({-href=>"$url"}, $text);
}

sub recruiterURL
{
    my $id = shift;
    return fullURL("manage.cgi?op=display;table=recruiter;id=$id");
}

##
## Caching routines
##

my %cache;

sub getName
{
    my $id = shift;
    if ( $id ) {
        my $rec = Recruiter::getRecord($id);
        return $rec->{'name'};
    } else {
        return "";
    }
}

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $recruiter = getRecordById({
            -table=>\%::RecruiterTable,
            -id=>$id,
        });
        $cache{$id} = $recruiter;
    } else {
        Database::addQueryComment("cache hit Recruiter $id");
    }
    return $cache{$id};
}


sub menuLabels
{
    my $rec = shift;
    my $result = $$rec{'name'};
    $result .=  " ($$rec{'agency'})" if ($$rec{'agency'});
    return $result;
}

sub isActive
{
    my $id = shift;
    my $rec = Recruiter::getRecord($id);
    return $rec->{'active'} eq 'Y';
}

sub isActiveSQL
{
    return "recruiter.active = " . SQLQuote("Y");
}

##
## The 'display' function can be called with either
## a ref to a hash record containing the record, or
## it can contain an id (a PK)
##

sub display
{
    my $rec;
    my ($p1) = (@_);
    if ( !$p1 ) {
        return "(none given)";
    }
    if ( ref($p1) eq "HASH" ) {
        $rec = $p1;
    } else {
        $rec = Recruiter::getRecord($p1);
        if ( !$rec ) {
            return "(recruiter deleted)";
        }
    }
    my $result = Recruiter::recruiterLink({
        -name=>$$rec{'name'},
        -agency => $$rec{'agency'},
        -id=>$$rec{'id'},
    });

    if ( $$rec{'email'} ) {
        my $url = "mailto:$$rec{'email'}";
        if ( $Subject ) {
            $url .= "?subject=$Subject";
            $Subject = undef;
        }

        $result .= "&nbsp;" . a({-href=>$url},
                     img({-src=>"images/envelope.jpg"}));
    }
    return $result;
}

sub mailSubject
{
    my ($subject) = (@_);
    $Subject = $subject;
}

1;
