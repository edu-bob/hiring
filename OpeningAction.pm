# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package OpeningAction;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(getInsertLinks
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);
use JSON;

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;
use User;

use OpeningActionTable;

my $metaData = \%::OpeningActionTable;

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
## XXX: getInsertLinks
##

sub getInsertLinks
{
    my ($action, $opening_id, $name) = (@_);
    my $recs = Database::getRecordsMatch({
        -column => 'opening_id',
        -table => $metaData,
        -value => $opening_id,
        -dojoin => 1,
                                        });
    my $html = "";
    $html .= Layout::start_script();
    my @actions = ();
    foreach my $rec ( @$recs ) {
        push @actions, { 
            'content' => $rec->{'action_id.action'},
        }
    }
    my $json = to_json(\@actions);
    $html .= "var action = $json;\n";
    $html .= "function insertAction(action,id,text){ var f=document.getElementById(action);f[id].value=text}\n";
    $html .= Layout::end_script();
    my $i = 0;
    foreach my $rec ( @$recs ) {
        $html .= p("Insert action: ",
            a({-href=>"",-style=>"cursor: pointer;", -onclick=>"insertEval('$action','$name',action[$i].action);return false"},$rec->{'action_id.action'}),
            );
        $i++;
    }
    return $html;
}

##
## generateCCJavaScript - generate the JavaScript that maps the opening_id to
## the list of user_id values on the CC list
##

sub generateActionJavaScript
{

    my $recs = Database::getRecordsWhere({
        -table => $metaData,
            -dojoin=>1
                                         });
    my @opening_ids = map { $_->{'opening_id'} } @$recs;
    my @actionmap;
    foreach my $opening_id ( @opening_ids ) {
        $actionmap[$opening_id] = [ map { $_->{'action_id'} }
                                    sort { $a->{'action_id.precedence'}<=>$b->{'action_id.precedence'} } grep {$_->{'opening_id'}==$opening_id} @$recs ];
    }

    my @actions;
    foreach my $action ( Action::getAll() ) {
        $actions[$action->{'id'}] = $action->{'action'};
    }

    my $js = '';
    use JSON;

    $js = join('', map { $_ . "\n" } (
                   "var actionmap = new Array();",
                   "actionmap = " . encode_json(\@actionmap) . ';',
                   'actions = new Array();',
                   'actions = ' . encode_json(\@actions) . ';',
    ));
    return $js;
}




1;
