# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Candidate;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 &candidateLink
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use CandidateTable;
use UserTable;
use CcTable;

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;
use User;
use Recruiter;
use Schedule;

my $metaData = \%::CandidateTable;

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
    $cvtlist->{'candidate_id'} = \&Candidate::convert;
}

sub convert
{
    my $value = shift;
    if ( $value ) {
        my @recs = getRecordsMatch({-table=>\%::CandidateTable, -column=>"id", -value=>$value});
        if ( scalar @recs == 0 ) {
            return "#$value (deleted)";
        } else {
            return Candidate::candidateLink({-id=>$value,
                                             -name=>$recs[0]->{'name'}});
        }
    } else {
        return "NULL";
    }
}


sub candidateLink
{
    my $argv = shift;
    argcvt($argv, ["id"], ["name"]);

    my $text;
    if ( $$argv{'name'} ) {
        $text = $$argv{'name'};
    } else {
        my $candidate = getRecordById({
            -table=>\%::CandidateTable,
            -id=>$$argv{'id'},
            });
        $text = $$candidate{'name'};
    }
    my $url = candidateURL($$argv{'id'});
    return a({-href=>"$url"}, $text);
}

sub candidateURL
{
    my $id = shift;
    return fullURL("candidates.cgi?op=get;id=$id");
}

##
## mailRecipients - build a list of e-mail recipients for a candidate
##
## Returns an array of user records for the owner and the CCs but only
## those that are marked 'active' and 'sendmail'
##
## Call must be one of these forms:
##     @list = Candidate::mailRecipients({-candidate => $hash});
##     @list = Candidate::mailRecipients({-candidate_id => $id});
##
## Optional arguments:
##    candididate ....... if provided, is used as the candidate hash
##    candidate_id ...... otherwise, if this is provided, is used to look up
##                        the candidate and retrieve its hash
##
## Return value:
##    An array of User hashes.

sub mailRecipients
{
    my $argv = shift;
    argcvt($argv, [], ['candidate', 'candidate_id']);

    my $candidate;

    if ( exists $$argv{'candidate'} ) {
        $candidate = $$argv{'candidate'};
    } elsif ( exists $$argv{'candidate_id'} ) {
        $candidate = Candidate::getRecord($$argv{'candidate_id'});
    } else {
        Utility::redError("Botch in Candidate::mailRecipients - neither candidate nor id given");
        return undef;
    }

    my @emails;
    my %dups;

    if ( $$candidate{'owner_id'} ) {
        my $owner = User::getRecord($$candidate{'owner_id'});
        
        if ( $owner->{'active'} eq 'Y' && $owner->{'sendmail'} eq 'Y' ) {
            push @emails,$owner;
            $dups{$owner->{'id'}} = 1;
        }
    }
    my @ccs = getRecordsMatch({-table=>\%::CcTable,
                               -value=>$candidate->{'id'},
                               -column=>"candidate_id",
                               -dojoin=>0});

    foreach my $cc ( @ccs ) {
        if ( !exists $dups{$cc->{'user_id'}} ) {
            my $ccuser = User::getRecord($cc->{'user_id'});
            if ( $ccuser->{'active'} eq 'Y' && $ccuser->{'sendmail'} eq 'Y' ) {
                push @emails, $ccuser;
                $dups{$ccuser->{'id'}} = 1;
            }
        }
    }
    return @emails;
}

##
## Caching routines
##

my %cache;

sub getName
{
    my $id = shift;
    my $rec = Candidate::getRecord($id);
    return $rec->{'name'};
}

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $candidate = getRecordById({
            -table=>\%::CandidateTable,
            -id=>$id,
        });
        $cache{$id} = $candidate;
    } else {
        Database::addQueryComment("cache hit Candidate $id");
    }
    return $cache{$id};
}

sub invalidateCache
{
    my $id = shift;
    delete $cache{$id};
}

##
## Return the name of the referrer, whether it be a referrer or a recruiter
##

sub getReferrer
{
    my $rec = shift;
    if ( $$rec{'referrer_type'} && $$rec{'referrer_type'} eq 'RECRUITER' ) {
        return Recruiter::getName($$rec{'recruiter_id'});
    } else {
        return $$rec{'referrer'};
    }
}

##
## changeOpening - hook function for generating "onchange" Javascript.
##
## Returns a javascript snippet to add to the "onchange" attribute on the "opening" field.
##

sub changeOpening
{
#    return "alert('Opening Changed.');";
    return "";
}


##
## getInterviewers - return an array of interviewers for the given candidate
##
## Return a hash indexed by a user_id, containing a ref to an array of hashes
## containing
##
## user_id => [
##               { interview_slot => ref to interview_slot,
##                 interview => ref to interview
##               },
##               ...
##            ];
##

sub getInterviewers
{
    my $id = shift;
    my @schedules = getRecordsMatch({
	-table=>\%::InterviewTable,
	-column=>"candidate_id",
	-value=>$id,
    });
    if ( scalar @schedules == 0 ) {
        return undef;
    }
    my %results;
    foreach my $s ( @schedules ) {
        my $users = Schedule::getInterviewers($s->{'id'});
        foreach my $user ( keys %$users ) {
            push @{$results{$user}}, $users->{$user};
        }
    }
#    Utility::ObjDump(\%results);
    return \%results;

}

sub formatRatings
{
    my $id = shift;
    my $result = "";

    my @ratings = getRecordsMatch({
	-table=>\%::RatingTable,
	-column=>"candidate_id",
	-value=>$id,
    });
    if ( scalar @ratings == 0 ) {
	$result .= p("None.");
    } else {
	$result .= start_table({-cellpadding=>"4"});
	$result .= Tr(
		 td(b("When")),
		 td(b("By")),
		 td(b("Rating")),
		 td(b("Short Comment")),
		 );
	my $sum = 0;
	foreach my $c ( @ratings ) {
	    my $r = User::getRecord($c->{'user_id'});

	    $result .= Tr(
		     td($c->{'creation'}),
		     td($$r{'name'}),
		     td({-align=>"right"}, $c->{'rating'}),
		     td(Utility::cvtTextline($c->{'comment'})),
		     );
	    $sum += $c->{'rating'};
	}
	$result .= Tr(
		 td("\&nbsp;"),
		 td({-align=>"right"}, b("Average")),
		 td({-align=>"right"}, sprintf("%.2f", $sum / scalar(@ratings))),
		 td("\&nbsp;"),
		 );
	$result .= end_table;
    }
    return $result;
}

##
## This is used by the calendar function
##

sub getCandidatesByDate
{
    my ($time, $type) = (@_);
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($time);
    my $date = sprintf("%04d-%02d-%02d", 1900+$year, $month+1, $day_of_month);
    my @candidates = getRecordsMatch({
        -table=>\%::CandidateTable,
        -column=>"date(candidate.creation)",
        -value=>$date,
        -dojoin => 2,
    });
#    print Utility::ObjDump(\@candidates);
    my $result = "";
    my $sep = "";
    my %people;

    $result = join(br(), map { candidateLink({-id=>$_->{'id'},-name=>$_->{'name'}}) . " ($_->{'opening_id.number'})" } @candidates);
    return $result;
}

1;
