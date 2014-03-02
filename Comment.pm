# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Comment;


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

use CommentTable;

my $metaData = \%::CommentTable;

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
    $cvtlist->{'comment.comment'} = \&Comment::convert_comment;
    $cvtlist->{'candidate.comment'} = \&Comment::convert_candidate;
}

sub convert_candidate
{
    my $value = shift;
    my $rec = Comment::getRecord($value);
    if ( !defined $rec ) {
        return "#$value (deleted)";
    } else {
        return Comment::link($value) . ": " . convert_comment($rec->{'comment'});
    }
}

sub convert_comment
{
    my $value = shift;
    my $comment_length = 25;

    if ( length($value) > $comment_length ) {
        return substr($value, 0, $comment_length) . " . . .";
    }
    return $value;
}

sub link
{
    my $value = shift;
    my $url = Layout::fullURL("candidates.cgi") . "?op=viewcomment;id=$value";
    return a({-href=>$url}, $value);
}

##
## Caching routines
##

my %cache;

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $comment = getRecordById({
            -table=>\%::CommentTable,
            -id=>$id,
        });
        $cache{$id} = $comment;
    } else {
        Database::addQueryComment("cache hit Comment $id");
    }
    return $cache{$id};
}

1;
