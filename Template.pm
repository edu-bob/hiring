# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Template;

##
## Templates are snippets of text or HTML that can be inserted into
## text boxes on various forms around the application.  They are used,
## for example, for standard interview instructions, structured
## review comments, and so on.
##


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p *script);

use Login;
use Database;
use Argcvt;
use Layout;
use Utility;

use TemplateTable;

my $TEMPLATE_CHOOSE = "-- NO TEMPLATE --";

my $metaData = \%::TemplateTable;

sub getTable
{
    return $metaData;
}
sub getTableName
{
    return $metaData->{'table'};
}


##
## Caching routines
##

my %cache;

sub getRecord
{
    my $id = shift;
    if ( !exists $cache{$id} ) {
        my $template = getRecordById({
            -table=>\%::TemplateTable,
            -id=>$id,
        });
        $cache{$id} = $template;
    } else {
        Database::addQueryTemplate("cache hit Template $id");
    }
    return $cache{$id};
}


sub getMenu
{
    my $argv = shift;
    argcvt($argv, ["table", "column", "control"],["suffix", "index"]);
    my $table = $$argv{'table'};
    my $column = $$argv{'column'};
    my $control = $$argv{'control'};
    
    my @templates = Database::getRecordsMatch({
        -table => Template::getTable(),
        -column => ['table_name', 'column_name'],
        -value => [$table, $column],
    });

    if ( scalar @templates == 0 ) {
        return "";
    }

#    return "";
## XXX This doesn't work yet

    my $result = "";
    my @values = ();
    my %labels = ();
    push @values, 0;
    $labels{"0"} = $TEMPLATE_CHOOSE;

## var templates = new Array();
## templates[1] = 'some template value';
## templates[4] = 'some other value';
## onchange='form.control[index].value=templates[id];

    my $varname = "T_$control";
    $result .= start_script();
    $result .= "var $varname = new Array();\n";
    $result .= "$varname\[0] = '';\n";
    foreach my $rec ( @templates ) {
        my $string = $rec->{'template'};
        $string =~ s/[\r]//g;
        $string =~ s/\n/\\n/gs;
        $string =~ s/(['])/\\$1/gs; #'
        push @values, $rec->{'id'};
        $labels{$rec->{'id'}} = $rec->{'name'};
        $result .= $varname . "[$rec->{'id'}] = '";
        $result .= $string;
        $result .= "';\n";
    }
    $result .= end_script();

    my $onchange = Layout::getForm() . ".$control";
    if ( exists $$argv{'index'} ) {
        $onchange .= '[' .$$argv{'index'} . ']';
    }
    $onchange .= ".value = " . $varname . "[this.value];\n",

    $result .= popup_menu({
        -name => "template.$table.$column",
        -values => \@values,
        -labels => \%labels,
        -onchange=> $onchange,
    });
    return $result;
}

1;
