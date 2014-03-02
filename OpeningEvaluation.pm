# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package OpeningEvaluation;


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

use OpeningEvaluationTable;

my $metaData = \%::OpeningEvaluationTable;

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
    my ($form, $opening_id, $name) = (@_);
    my $recs = Database::getRecordsMatch({
        -column => 'opening_id',
        -table => $metaData,
        -value => $opening_id,
        -dojoin => 1,
                                        });
    my $html = "";
    $html .= Layout::start_script();
    my @forms = ();
    foreach my $rec ( @$recs ) {
        push @forms, { 
            'content' => $rec->{'evaluation_id.content'},
            'prompt' => $rec->{'evaluation_id.prompt'},
        }
    }
    my $json = to_json(\@forms);
    $html .= "var evaluation = $json;\n";
    $html .= "function insertEval(form,id,text,prompt){ var f=document.getElementById(form);f[id].value=text;alert(prompt)}\n";
    $html .= Layout::end_script();
    my $i = 0;
    foreach my $rec ( @$recs ) {
        $html .= p("Insert evaluation form: ",
            a({-href=>"",-style=>"cursor: pointer;", -onclick=>"insertEval('$form','$name',evaluation[$i].content,evaluation[$i].prompt);return false"},$rec->{'evaluation_id.title'}),
            );
        $i++;
    }
    return $html;
}





1;
