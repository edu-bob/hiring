# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package OptionMenuWidget;


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

    my @values = param($name);
    return @values;
}

sub type
{
    return "Option Menu";
}


##
## OptionMenu - make an option menu from a column
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
##

sub widget
{
    my $argv = shift;
    argcvt($argv, ["table", "column", "form"],
           ['multiple', 'size', 'default', 'onchange', 'null', 'name','suffix', 'skipfilters']);
    my $table = $$argv{'table'};
    my $column = Layout::findColumn($argv);
    my $theForm = $$argv{'form'};

    my @values = ();

    my $result = "";
    my %labels = ();

  TYPE: {
      $column->{'type'} eq "enum" and do {
          @values = EnumsList($table->{'table'}, $column->{'column'});
          foreach my $v ( @values ) {
              $labels{$v} = $v;
          }
          last TYPE;
      };
      $column->{'type'} eq "set" and do {
          @values = SetList($table->{'table'}, $column->{'column'});
          foreach my $v ( @values ) {
              $labels{$v} = $v;
          }
#Utility::ObjDump(\%labels);
#Utility::ObjDump($$argv{'default'});
          last TYPE;
      };
      $column->{'type'} eq "bitvector" and do {
          if ( ref($column->{'labels'}) eq "ARRAY" ) {
              for ( my $i=0 ; $i<scalar(@{$column->{'labels'}}) ; $i++ ) {
                  push @values, $i;
                  $labels{$i} = $column->{'labels'}->[$i];
              }
          } elsif ( ref $column->{'labels'} eq "CODE" ) {
              my @tmplabels = &{$column->{'labels'}};
              for ( my $i=0 ; $i<scalar(@tmplabels) ; $i++ ) {
                  push @values, $i;
                  $labels{$i} = $tmplabels[$i];
              }
          } else {
              Utility::redError("Unknown ref type");
          }
          last TYPE;
      };

      ## Otherwise, the selected column must be read from the database

      ## Apply any DB filters that may be in the metadata table

      my $where = undef;
      my %skipfilters;
      if ( exists $argv->{'skipfilters'} ) {
          foreach my $filtername ( @{$argv->{'skipfilters'}} ) {
              $skipfilters{$filtername} = 1;
          }
      }
      if ( ref($table->{'filters'}) eq "ARRAY" ) {
          foreach my $frec ( @{$table->{'filters'}} ) {
              next if ( exists $frec->{'name'} && exists $skipfilters{$frec->{'name'}} );
              if ( exists $frec->{'activeSQL'} ) {
                  $where = &{$frec->{'activeSQL'}}();
              }
          }
      } else {
          next if ( exists $table->{'filters'}->{'name'} && exists $skipfilters{$table->{'filters'}->{'name'}} );
          if ( exists $table->{'filters'}->{'activeSQL'} ) {
              $where = &{$table->{'filters'}->{'activeSQL'}}();
          }
      }
      my @recs = Database::getRecordsWhere({
          -table => $table,
          -where => $where,
      });

      foreach my $rec ( @recs ) {
          push @values, $$rec{'id'};
          if ( $$column{'labels'} ) {
              $labels{$$rec{'id'}} = &{$$column{'labels'}}($rec);
          } else {
              $labels{$$rec{'id'}} = $$rec{$$column{'column'}};
          }
      }
  };

    if ( $$argv{'null'} ) {
        unshift @values, 0;
        $labels{"0"} = $$argv{'null'};
    }

    my $name = $$argv{'name'} ? $$argv{'name'} : $$argv{'column'};
    if ( $$argv{'suffix'} ) {
        $name .= $$argv{'suffix'};
    }


    my %args = (
                -name=>$name,
                -values=>\@values,
                -labels=>\%labels,
                );

    if (exists $$argv{'size'} and $$argv{'size'} ) {
        $args{'-size'} = $$argv{'size'};
        if ( $args{'-size'} > scalar(@values) ) {
            $args{'-size'} = scalar(@values);
        }
    } else {
        $args{'-size'} = scalar(@values) > 5 ? 5 : scalar @values;
    }
    exists $$argv{'multiple'} and $args{'-multiple'} = "true";
    exists $$argv{'default'}  and $args{'-default'} = $$argv{'default'};
    exists $$argv{'onchange'} and $args{'-onchange'} = $$argv{'onchange'};
    
    return scrolling_list(\%args);
}



1;
