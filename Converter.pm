# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Converter;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(ConvertToPrintable
			 );

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p);

use Argcvt;
use User;
use Data::Dumper;

my $Converters;

sub addConverter
{
    my $ref = shift;
#    print "Converter::addConverter add ",Dumper($ref);
    foreach my $k ( keys %$ref ) {
        $Converters->{$k} = $ref->{$k};
    }
}

sub getConverterRef
{
    return $Converters;
}


##
## Converter::convertToDisplayable
##
## Given a value from a given (required) column in a given (optional) table,
## convert it to a displayable string.  This works by using the object-specific
## converters initialized in Application::Init.  The converters are keyed
## by either "table.column" or just "column" values.  When called, they are
## passed only the column portion and the optional "label" which can be used
## for any reason but intended be used when the value to convert is a foreign
## key in which case the "label" typically names a column in the foreign
## table.
##
## Required parameters:
##    value .... the value to convert
##    column ... the name of the column in the source table, that "value" comes from.
## Optional parameters:
##    table .... the name or HASH metadata of the table that "column" comes from
##    label .... passed as arg2 to the object-specific converter
##
## Converter prototype:
##   The registered converters will be called via
##       converter(value, label)
##

sub convertToDisplayable
{
    my ($argv) = (@_);
    argcvt($argv, ['value', 'column'], ['table', 'label']);
    my $table = ref($$argv{'table'}) eq "HASH" ? $$argv{'table'}->{'table'} : $$argv{'table'};

    my $newvalue = $$argv{'value'};

    ##
    ## First process the known converters
    ##

  SWITCH: {
      $$argv{'column'} eq "owner_id" || $$argv{'column'} eq "user_id" and do {
          $newvalue = User::getName($$argv{'value'});
          last SWITCH;
      };
  }
    
    ##
    ## next, look for application-specific converters
    ##

    if ( defined $Converters ) {
        if ( exists $Converters->{"$table.$$argv{'column'}"} ) {
            $newvalue = &{$Converters->{"$table.$$argv{'column'}"}}($$argv{'value'}, $$argv{'label'});
        } elsif ( exists $Converters->{$$argv{'column'}} ) {
            $newvalue = &{$Converters->{$$argv{'column'}}}($$argv{'value'}, $$argv{'label'});
        }
    }
    return defined $newvalue ? $newvalue : "NULL";
}


1;

