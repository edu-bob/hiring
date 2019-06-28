# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package LeftRightWidget;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use Database;
use Argcvt;
use Layout;
use Utility;


sub getParamValue
{
    my ($name) = (@_);

    my @values = split(/,/, param($name));
    return @values;
}

sub type
{
    return "Left/Right";
}

##
## LeftRightWidget - make an option menu from a column
##
## Required named parameters:
##    table ... hash ref of the table metadata
##    column .. name of the column
##
## Optional named parameters:
##    multiple ... define if multiple selections allowed
##    size ....... number of widget rows to display 
##    default .... array of selected values
##    name ....... form element name, defaults to the column name
##    onchange ... JavaScript for "onchange" function
##    skipfilters ... ref to array of filter names to skip
##
##

sub widget
{
    my $argv = shift;
    argcvt($argv, ["form", "table", "column"],
           ['multiple', 'size', 'default', 'onchange', 'null', 'name','suffix','skipfilters']);
    my $table = $$argv{'table'};
    my $column = Layout::findColumn($argv);
    my $theForm = $$argv{'form'};


    my @valuesLeft = ();
    my %labelsLeft = ();
    my @valuesRight = ();
    my %labelsRight = ();

    my $name = $$argv{'name'} ? $$argv{'name'} : $$argv{'column'};
    if ( $$argv{'suffix'} ) {
        $name .= $$argv{'suffix'};
    }
    my $fullName = "document.$theForm.$name";
    my $fullFormName = "document.$theForm";
    my $elementNameLeft = $name . "_list";
    my $elementNameRight = $name . "_selected";
    my $nameLeft = "document.$theForm.$elementNameLeft";
    my $nameRight = "document.$theForm.$elementNameRight";

    my %selected;
    foreach my $v ( @{$argv->{'default'}} ) {
        $selected{$v} = 1;
    }

  TYPE: {
      $column->{'type'} eq "enum" and do {
          foreach my $v ( EnumsList($table->{'table'}, $column->{'column'}) ) {
              if ( ! exists $selected{$v} ) {
                  push @valuesLeft, $v;
                  $labelsLeft{$v} = $v;
              } else {
                  push @valuesRight, $v;
                  $labelsRight{$v} = $v;
              }
          }
          last TYPE;
      };
      $column->{'type'} eq "set" and do {
          foreach my $v ( SetList($table->{'table'}, $column->{'column'}) ) {
              if ( !exists $selected{$v} ) {
                  push @valuesLeft, $v;
                  $labelsLeft{$v} = $v;
              } else {
                  push @valuesRight, $v;
                  $labelsRight{$v} = $v;
              }
          }
          last TYPE;
      };
      $column->{'type'} eq "bitvector" and do {
          if ( ref($column->{'labels'}) eq "ARRAY" ) {
              for ( my $i=0 ; $i<scalar(@{$column->{'labels'}}) ; $i++ ) {
                  if ( !exists $selected{$i} ) {
                      push @valuesLeft, $i;
                      $labelsLeft{$i} = $column->{'labels'}->[$i];
                  } else {
                      push @valuesRight, $i;
                      $labelsRight{$i} = $column->{'labels'}->[$i];
                  }
              }
          } elsif ( ref $column->{'labels'} eq "CODE" ) {
              my @tmplabels = &{$column->{'labels'}};
              for ( my $i=0 ; $i<scalar(@tmplabels) ; $i++ ) {
                  if ( !exists $selected{$i} ) {
                      push @valuesLeft, $i;
                      $labelsLeft{$i} = $tmplabels[$i];
                  } else {
                      push @valuesRight, $i;
                      $labelsRight{$i} = $tmplabels[$i];
                  }
              }
          } else {
              Utility::redError("Unknown ref type");
          }
          last TYPE;
      };

      ## Otherwise, the selected column must be read from the database

      my $where = undef;
      if ( exists $table->{'filters'} ) {
          my %skipfilters;
          if ( exists $argv->{'skipfilters'} ) {
              foreach my $filtername ( @{$argv->{'skipfilters'}} ) {
                  $skipfilters{$filtername} = 1;
              }
          }
          if ( ref($table->{'filters'}) eq "ARRAY" ) {
              foreach my $fref ( @{$table->{'filters'}} ) {
                  next if ( exists $fref->{'name'} && exists $skipfilters{$fref->{'name'}} );
                  if ( exists $fref->{'activeSQL'} ) {
                      $where = &{$fref->{'activeSQL'}}();
                  }
              }
          } else {
              if ( exists $table->{'filters'}->{'activeSQL'} ) {
                  next if ( exists $table->{'filters'}->{'name'} && exists $skipfilters{$table->{'filters'}->{'name'}} );
                  $where = &{$table->{'filters'}->{'activeSQL'}}();
              }
          }
      }
      my @recs = Database::getRecordsWhere({
          -table => $table,
          -where => $where,
      });

      foreach my $rec ( @recs ) {
          if ( !exists $selected{$$rec{'id'}} ) {
              push @valuesLeft, $$rec{'id'};
              if ( $$column{'labels'} ) {
                  $labelsLeft{$$rec{'id'}} = &{$$column{'labels'}}($rec);
              } else {
                  $labelsLeft{$$rec{'id'}} = $$rec{$$column{'column'}};
              }
          } else {
              push @valuesRight, $$rec{'id'};
              if ( $$column{'labels'} ) {
                  $labelsRight{$$rec{'id'}} = &{$$column{'labels'}}($rec);
              } else {
                  $labelsRight{$$rec{'id'}} = $$rec{$$column{'column'}};
              }
          }
      }
  };

#    if ( $$argv{'null'} ) {
#        unshift @valuesLeft, 0;
#        $labelsLeft{"0"} = $$argv{'null'};
#    }

    my %args = (
                -name=>$elementNameLeft,
                -values=>\@valuesLeft,
                -labels=>\%labelsLeft,
                );

    if (exists $$argv{'size'} and $$argv{'size'} ) {
        $args{'-size'} = $$argv{'size'};
        if ( $args{'-size'} > scalar(@valuesLeft)+scalar(@valuesRight) ) {
            $args{'-size'} = scalar(@valuesLeft)+scalar(@valuesRight);
        }
    } else {
        $args{'-size'} = scalar(@valuesLeft)+scalar(@valuesRight) > 5 ? 5 : scalar @valuesLeft+scalar(@valuesRight);
    }
    exists $$argv{'multiple'} and $args{'-multiple'} = "true";
#    exists $$argv{'onchange'} and $args{'-onchange'} = $$argv{'onchange'};

    my $result;
    $result .= start_table . "\n";

    $result .= Tr(
                  td({-align=>"center"}, b("Not Included")),
                  td("&nbsp;"),
                  td({-align=>"center"}, b("Included")),
                  );
    $result .= start_Tr . "\n";
    $result .= start_td . "\n";
    $result .= scrolling_list(\%args);
    $result .= end_td . "\n";

    $result .= start_td . "\n";

    $result .= button({
        -value=>"&nbsp;&#8594;&nbsp;",
        -onClick=>"LR_moveSelectedItem($nameLeft, $nameRight);LR_buildresult($nameRight,$fullName)",
    }) . br . "\n";
    $result .= button({
        -value=>"&nbsp;&#8592;&nbsp;",
        -onClick=>"LR_moveSelectedItem($nameRight, $nameLeft);LR_buildresult($nameRight,$fullName)",
    }) . "\n";
    $result .= end_td . "\n";

    ##
    ## Create the list widget on the right to receive the
    ## items picked from the list on the left.
    ##

    my %args2 = (
                 -name=>$elementNameRight,
                 -values=>\@valuesRight,
                 -labels=>\%labelsRight,
                 -size=>$args{'-size'},
                );
    exists $$argv{'multiple'} and $args2{'-multiple'} = "true";

    $result .= start_td . "\n";
    $result .= scrolling_list(\%args2);
    $result .= end_td . "\n";

    $result .= end_Tr;
    $result .= end_table . "\n";
    $result .= hidden({-name=>$name, -value=>""});
    Layout::addInitialization("LR_buildresult($nameRight,$fullName)");
    return $result;
}



1;
