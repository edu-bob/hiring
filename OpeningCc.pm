# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package OpeningCc;


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
use User;

use OpeningCcTable;

my $metaData = \%::OpeningCcTable;

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
    $cvtlist->{'cc.user_id'} = \&Cc::convert;
}

sub convert
{
    my $value = shift;
    return User::getName($value);
}



##
## add - add a user to a given candidate's CC list
##
## Only does this if the candidate is not already on the CC list
##
## returns 0 if nothing added, 1 otherwise
##

sub add
{
    my ( $user_id, $candidate_id) = (@_);

    # check if this user is already on the CC list for the candidate

    if ( Cc::isIncluded( $user_id, $candidate_id) ) {
        return 0;
    }
    my $rec = {
        'user_id' => $user_id,
        'candidate_id' => $candidate_id,
    };
    Database::writeSimpleRecord({
        -table => $metaData,
        -record => $rec,
    });
    return 1;
}

##
## isIncluded - return true or false depending on whether a given user is on the CC list of a given candidate
##

sub isIncluded
{
    my ( $user_id, $candidate_id) = (@_);

    my @matches = Database::getRecordsMatch({
        -table => $metaData,
        -column => ['user_id', 'candidate_id'],
        -value => [$user_id, $candidate_id],
    });
    return scalar @matches > 0;
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
