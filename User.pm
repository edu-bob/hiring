# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package User;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;
use Password;

use UserTable;

my $metaData = \%::UserTable;

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
    $cvtlist->{'user_id'} = \&User::convert;
    $cvtlist->{'candidate.owner_id'} = \&User::convert;
}

sub convert
{
    my $value = shift;
    return User::getName($value);
}

##
## Caching routines
##

my %cache;

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
        $rec = User::getRecord($arg);
    }
    if ( $rec ) {
        return $rec->{'name'};
    } else {
        return "anonymous";
    }
}

sub getNamesLike
{
    my $str = shift;
    if ( !$str ) {
        return undef;
    }
    my $where = "name LIKE " . SQLQuote("$str");
    return Database::getRecordsWhere({
        -table=>\%::UserTable,
        -where=>$where,
    });
}


sub getRecord
{
    my $id = shift;
    if ( $id ) {
        if ( !exists $cache{$id} ) {
            my $user = getRecordById({
                -table=>\%::UserTable,
                -id=>$id,
            });
            $cache{$id} = $user;
        } else {
            Database::addQueryComment("cache hit User $id");
          }
        return $cache{$id};
    } else {
        return undef;
    }
}

sub getRecordByName
{
    my $name = shift;
    my @records = Database::getRecordsMatch({
        -table=>User::getTable(),
        -column=>"name",
        -value=>$name,
    });
    if ( scalar @records == 0 ) {
        return undef;
    } else {
        return $records[0];
    }
}

sub getRecordBy
{
    my $argv = shift;
    argcvt($argv, ["column","value"]);
    my @records = Database::getRecordsMatch({
        -table => User::getTable(),
        -column => $argv->{'column'},
        -value => $argv->{'value'},
                                            });
    if ( scalar @records == 0 ) {
        return undef;
    } else {
        return $records[0];
    }
}

sub isActive
{
    my $id = shift;
    my $rec = User::getRecord($id);
    return $rec->{'active'} eq 'Y';
}

sub isActiveSQL
{
    return "user.active = " . SQLQuote("Y");
}

sub cryptPassword
{
    return Password::encrypt(@_);
}

sub matchPassword
{
    return Password::match(@_);
}

sub getAll
{
    return Database::getAllRecords({
        -table=>$metaData,
    });
}

1;
