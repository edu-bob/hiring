# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Layout;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(
             &Footer
             &PulldownMenu
             &doInsertFromParams
             &doUpdateFromParams
             &doEditTable
             &doEntryForm
             &doHiddenForm
             &doEditForm
             &doStaticValues
             &doAccessDenied
             &fullURL
             &doMustLogin
             &doHeading
             &setHeadingRight
             &doSingleFormElement);

@EXPORT_OK = qw();              # Symbols to export on request


use CGI qw(:standard *table *ol *ul *Tr *td escape *p *div *script);
use Param;
use Login;
use Database;
use Argcvt;
use Utility;
use DateTime;
use LeftRightWidget;
use OptionMenuWidget;

use Data::Dumper;

##
## This string is placed under the "Home" link at the top right of the page
##

BEGIN {
    $Layout::headstr = "";
};


##
## start_form - replacement for CGI's start_form
##

my $theForm = "";
my $theStatus = "";
my $formIndex = 0;
my $validatorScript;
my $variantScript;
my %variants;

my $initializeScript;

my $NoChangesMsg = "Form status: Nothing has changed.";

##
## Form Management
##
## Typical Pattern:
##
##    # for editing an existing record:
##
##    print Layout::startForm();
##    print Layout::doEditForm({-table=> ,
##                              -record=> ,
##                             });
##    print Layout::endForm();
##
##    # in the POST routine
##
##    Layout::doUpdateFromParams({-table=> ,
##                               });
##



##
## Layout::startForm/endForm - start and end form with validation and
##                             status line
##
## These are to be used in conjunction with the other form routines that
## call doSingleFormElement:
##      doEditForm
##      doEntryForm
##      doHiddenForm
##
## Returns the HTML string to put at the top of a form.
##
## The args hash is the same as CGI::start_form with these exceptions:
##    -status ... generate a line that says whether or not the form has
##                changed.
##
## If -name is not given, a form name will be automatically generated.
## This is needed for the validation routines.
##

sub startForm
{
    my $argv = shift;
    $theForm = undef;
    my $dostatus = 0;

    autoEscape(undef);

    ## if an arglist if given, scan it for the -name parameter
    ## and extra argument (like -status)

    if ( ref($argv) eq "HASH" ) {
        foreach my $k ( keys %$argv ) {
            if ( $k eq "-name" ) {
                $theForm = $$argv{$k};
            }
            if ( $k eq "-status" ) {
                $dostatus = 1;
                delete $$argv{$k};
            }
        }
    }

    ## Generate a synthetic form name if none was given

    if ( !$theForm ) {
        $theForm = sprintf("form%03d", $formIndex);
        $$argv{'-name'} = $theForm;
    }
    if ( !$$argv{'-id'} ) {
        $$argv{'-id'} = $$argv{'-name'};
    }
    $formIndex++;

    ## Start the form.
    ##   $validatorScript ... this is where the javascript validations will
    ##                  be collected
    ##   $result ...... where the resulting HTML string is collected
    ##   $variantScript ... where the variables for managing variants are dumped
    ##   %variants ........ hash of variants already dumped
    ##   $initializeScript ... javascript that is executed once on each page

    ## XXX finish setting up initializeScript
    $validatorScript = "";
    $variantScript = "";
    $initializeScript = "";

    my $result = "\n\n<!-- FORM $theForm -->\n\n";
    $result .= CGI::start_form($argv);

    ## if -status given, put out the form change status field.

    if ( $dostatus ) {
        $result .= addStatusLine();
    }
    return $result;
}

sub getForm
{
    return $theForm;
}

sub addStatusLine
{
    $theStatus = $theForm . "_status";
    return div({-id=>$theStatus}, $NoChangesMsg) . "\n";
}

sub endForm
{
    my $argv = shift;
    my $str = CGI::end_form($argv) . "\n";

    ## Dump out the Javascript validations, if any

    if ( length($validatorScript) > 0 ) {
        $validatorScript = "\nvar v = new Validator(\"$theForm\");\n" . $validatorScript;
        $str .= CGI::script($validatorScript) . "\n";
        $validatorScript = "";
    }
    if ( length($variantScript) > 0 ) {
        $str .= CGI::script($variantScript) . "\n";
        $variantScript = "";
    }

    ## initializeScript - JavaScript for initializing the form

    if ( length($initializeScript) > 0 ) {
        $str .= CGI::script($initializeScript) . "\n";
        $initializeScript = "";
    }
    $theForm = undef;
    $theStatus = undef;
    return $str;
}

##
##  Layout::addValidation - add a form element validation to the list of validators.
##
##  Call this if you are creating form elements outside of one of the
##  subroutines in this package.
##
##  Required input parameters:
##      -column ... refers to a column in a table metadata hash.
##                  This can be a reference to one element in the
##                  columns array, or it can be a string that is the name
##                  of the column.  If it is a string,
##                  then -table MUST be provided as well
##  Optional input parameters:
##      -table .... required if -column is a string.  Ref to a table metadata hash.
##      -suffix ... optional suffix for the form element name
##
## Example:
##    print CGI::textfield({-name=>"a_column_name", ... });
##    Layout::addValidation({-column=>"a_column_name", -table=>\%::SomeTable});
##

sub addValidation
{
    $validatorScript .= formValidate(@_);
}

##
##  Layout::addInitialization - add a JavaScript form element initialization to
##                              the list of initializers.
##

sub addInitialization
{
    $initializeScript .= join("\n", @_);
}

##
## Layout::addStatusCheck - add a status check -onchange argument to
##                          some CGI::arg list
##
## Use this routine if you are calling CGI form routines directly.
## It will add the proper -onchange argument to the args list so that
## the status line is updated correctly
##
## Required input parameters:
##    args ... ref to a hash that will be passed to a CGI:: routine
## Optional input parameters:
##    default ... default value for the form element, used to detect
##                a real data change
##    onchange .. additional javascript for the onchange element
##
## Example:
##    my $args = { -name=>"some_form_element", ... };
##    Layout::addStatusCheck({-args=>$args});
##

sub addStatusCheck
{
    my $argv = shift;
    argcvt($argv, ["args"], ['default']);
    my $args = $$argv{'args'};
    if ( $$args{'-onchange'} ) {
        $$args{'-onchange'} .= ";";
    }
    $$args{'-onchange'} .= statusCheckOnChange($argv);
}

## Generate the combined "onchange" value having what the caller provided
## and the status line update call.

sub statusCheckOnChange
{
    my $argv = shift;
    argcvt($argv, [], ['args', 'default']);
    my $result = "";
    if ( $theStatus ) {
        if ( exists $$argv{'default'} ) {
            my $def = defined $$argv{'default'} ? $$argv{'default'} : "";
            $def =~ s/\x0A/\\n/gs;
            $result = "modified1(this, '" . $def . "', '$theStatus')";
        } else {
            $result = "modified0(this, '$theStatus')";
        }
    }
    return $result;
}

## Generate the combined "onchange" value having what the caller provided
## and any table/column-specific action, plus any extra caller function

sub addOnChange
{
    my $argv = shift;
    argcvt($argv, ['table', 'column'], ['args', 'default', 'clientonchange']);
    my $args = $$argv{'args'};
    my $table = $$argv{'table'};
    my $column = $$argv{'column'};
    my $result = "";

    if ( $$argv{'clientonchange'} ) {
        if ( $$args{'-onchange'} ) {
            $$args{'-onchange'} .= ';';
        }
        $$args{'-onchange'} .= $$argv{'clientonchange'};
    }
    if ( $column->{'changeHook'} ) {
        if ( $$args{'-onchange'} ) {
            $$args{'-onchange'} .= ";";
        }
        $$args{'-onchange'} .= &{$column->{'changeHook'}}($argv);
    }
}

##
## addVariant - add the javascript to a form element to handle being
##              part of a group.
##
##

sub addVariant
{
    my $argv = shift;
    argcvt($argv, ['table', 'column'], ['args', 'default']);
    my $args = $$argv{'args'};
    my $table = $$argv{'table'};
    my $result;

    # The column argument could be a ref into the table metadata table or
    # it could be a column string name.  Convert it. if needed, to a
    # table hash reference, $tcol

    my $tcol = ref($$argv{'column'}) eq "HASH" ?
        $$argv{'column'} :
        findColumn({-table=>$$argv{'table'},
                    -column=>$$argv{'column'}});

    # This column must be member of a group to continue

    if ( !exists $$tcol{'group'} ) {
        return;
    }
    if ( exists $$tcol{'switch'} ) {
        $result = addVariantOnOff({
            -table=>$table,
            -column=>$tcol,
        });

        ## XXX generate more into $variantScript if not already in %variants,
        ## both the array and the call to the fix routine

        if ( !exists $variants{$$tcol{'column'}} ) {
            $variants{$$tcol{'column'}} = 1;
            $variantScript .= "var variant_$$tcol{'column'} = [";

            my $sep = "";
            my $group = $$table{'groups'}{$$tcol{'group'}};
            foreach my $g ( @{$$group{'cases'}} ) {
                $variantScript .= "$sep\n  [ '$$g{'column'}',\n";
                $variantScript .= "    [ " . join(",", map { "'$_'" } @{$$g{'value'}}) . " ]\n";
                $variantScript .= "  ]";
                $sep = ",";
            }

            $variantScript .= "\n];\n";
            $variantScript .= $result;
        }
    } else {
        $result = "";
    }
    if ( $result ) {
        if ( $$args{'-onchange'} ) {
            $$args{'-onchange'} .= ";";
        } else {
            $$args{'-onchange'} = " ";
        }
        $$args{'-onchange'} .= $result;
    }
}

# returns the onchange javascript for a variant switch value

sub addVariantOnOff
{
    my $argv = shift;
    argcvt($argv, ['table', 'column'], ['suffix']);
    my $table = $$argv{'table'};
    my $suffix = exists $$argv{'suffix'} ? $$argv{'suffix'} : "";

    # The column argument could be a ref into the table metadata table already

    my $tcol = ref($$argv{'column'}) eq "HASH" ?
        $$argv{'column'} :
        findColumn({-table=>$$argv{'table'},
                    -column=>$$argv{'column'}});

    return undef if ( !$$tcol{'switch'} );
    my $group = $$table{'groups'}{$$tcol{'group'}};
##    Utility::ObjDump($group);

    return "fix_variant('$theForm', '$$tcol{'column'}" . $suffix . "')";
}

##
## variantDiv - wrap text (a form element) in a div that can be used to turn a form element
##              on and off
##

sub variantDiv
{
    my $argv = shift;
    argcvt($argv, ['column'], ['suffix']);
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";
    my $result;

    $result = start_div({
        -id=>"div_$theForm" . "_$$argv{'column'}$suffix",
    });
    $result .= join("", @_);
    $result .= end_div;
    return $result;
}


##
## Footer - short page footer
##
## Arguments:
##    hidelogin ... 1=>don't show login/out footer
##    hidesql ..... 1=>don't show SQL debug button
##    url ......... URL of this page to return to if login/out used

sub Footer
{
    Database::addQueryComment("Footer");
    my $argv = $_[0];
    if ( ref($argv) eq "HASH" ) {
        argcvt($argv, []);
        shift;
    } else {
        $argv = 0;
    }

    my $return;
    if ( $argv && $$argv{'url'} ) {
        $return = $$argv{'url'};
    } else {
        $return = Utility::rootURL();
    }

    $return = escape($return);

    my $str = "\n<!-- FOOTER -->\n\n" . br();

    $str .= start_table({-border=>"0", -width=>"100%", -align=>"center", -class=>"footer"}) . "\n";
    $str .= start_Tr . "\n";
    $str .= td({-align=>"center", -class=>"footer"}, a({-href=>Utility::rootURL()}, "Home")) . "\n";
    if ( !($argv && $$argv{'hidelogin'}) ) {
        $str .= td({-align=>"center", -class=>"footer"}, "|") . "\n";
        $str .= td({-align=>"center", -class=>"footer"},
                   Login::isLoggedIn() ? (a({-href=>"loginout.cgi?op=logout&link=" . escape(url({-base=>1}))}, "Log out:"),
                                   " ", Login::getLoginName()) :
                   a({-href=>"loginout.cgi?link=$return"}, "Log in")) . "\n";
    }
    
    if ( cookie("query") ) {
        $str .= td({-align=>"center", -class=>"footer"}, "|") . "\n";
        $str .= td({-align=>"center", -class=>"footer"}, a({-href=>cookie("query")}, "Previous Query")) . "\n";
    }

    ## Send feedback to the author

    $str .= td({-align=>"center", -class=>"footer"}, "|") . "\n";
    $str .= td({-align=>"center", -class=>"footer"},
               a({-href=>"mailto:candidate-tracker\@openeye.com?subject=Candidate%20Tracker%20Feedback"},
                 "Send Feeback")) . "\n";

    # Create the "SQL" button if configured.

    if ( Param::getValueByName("show-sql") eq 'Y' && !($argv && $$argv{'hidesql'}) ) {
        $str .=  td({-align=>"center", -class=>"footer"}, "|") . "\n";
        $str .= td({-align=>"center", -class=>"footer"}, dumpQueries()) . "\n";
    }
    $str .= end_Tr . "\n";
    $str .= end_table . "\n";

    return $str;
}

#
# PulldownMenu - return a pulldown forms menu from a column in a table
#
# Required parameters:
#    -table => name of the DB table 
#    -column => name of the column 
# Optional parameters:
#    -default => Value in the list of values that is the default selected
#    -null => Define this if you want a "NONE" entry added to the menu
#    -onchange => JavaScript command for onchange
#    -name => form element name (defaults to column name)
#    -skipfilters => a named filter or a ref to an array of named filters to skip.  These
#                    are filters defined on the *Table hash.
#
# If filters are added, another "where" clause is added that makes sure that thde default
# value is always included.
#
# If the given column is an enum type, the enum values are put into the table.
# Otherwise, it is taken to be
# XXX the pattern here of concatenating filters and ORing in the default value needs 
#     to migrate to OptionWidget and (maybe) LeftRight
#

sub PulldownMenu
{
    my $argv = shift;
    argcvt($argv, ["table", "column"],
           ['null', 'default', 'onchange', 'name', 'suffix', 'skipfilters','id',
           'clientonchange']);
    my $table = $$argv{'table'};
    my $column = findColumn($argv);
    my @values = ();

    my $result = "";
    my %labels = ();
#    Utility::ObjDump($argv);

  TYPE: {
      $column->{'type'} eq "enum" and do {
          @values = EnumsList($table->{'table'}, $column->{'column'});
          foreach my $v ( @values ) {
              $labels{$v} = $v;
          }
          last TYPE;
      };

      $column->{'type'} eq "bitvector" and do {
          for ( my $i=0 ; $i<scalar(@{$column->{'labels'}}) ; $i++ ) {
              push @values, $i;
              $labels{$i} = $column->{'labels'}->[$i];
          }
          last TYPE;
      };

      # the default type is that this is a FK to another table

      # apply any filter, such as eliminating inactive users
      # the 'filters" entry can be a single item or an array of items; this
      # is too much flexibility but is this way for backward compatibility

      my $where = undef;
      if ( exists $table->{'filters'} ) {
          my %skipfilters;
          if ( exists $argv->{'skipfilters'} ) {
              foreach my $filtername ( @{$argv->{'skipfilters'}} ) {
                  $skipfilters{$filtername} = 1;
              }
          }
          if ( ref($table->{'filters'}) eq "ARRAY" ) {
              my $sep = "";
              foreach my $fref ( @{$table->{'filters'}} ) {
                  next if ( exists $fref->{'name'} && exists $skipfilters{$fref->{'name'}} );
                  if ( exists $fref->{'activeSQL'} ) {
                      $where .= $sep . &{$fref->{'activeSQL'}}();
                      $sep = " AND ";
                  }
              }
          } else {
              if ( exists $table->{'filters'}->{'activeSQL'} ) {
                  next if ( exists $table->{'filters'}->{'name'} && exists $skipfilters{$table->{'filters'}->{'name'}} );
                  $where = &{$table->{'filters'}->{'activeSQL'}}();
              }
          }

          # If there is a default value and there are filters, then make sure that thde default
          # value gets included.

          if ( $$argv{'default'}  && $where ) {
              $where = "( $where ) OR ( id = " . SQLQuote($$argv{'default'}) . " )";
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
                -values => \@values,
                -labels => \%labels,
                );

    exists $$argv{'default'} and $args{'default'} = $$argv{'default'};
    exists $$argv{'onchange'} and $args{'onchange'} = $$argv{'onchange'};
    $$argv{'id'} and $args{'id'} = $$argv{'id'};

    return popup_menu(\%args);
}

sub findColumn
{
    my $argv = shift;
    argcvt($argv, ['table', 'column']);
    my $table = $$argv{'table'};
    my $column = $$argv{'column'};

    foreach my $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'column'} eq $column ) {
            return $tcol;
        }
    }
    Utility::redError("Can't find column \"$column\" in table metadata \"$table->{'table'}\"");
    return undef;
}



##
## doInsertFromParams - insert a DB row based on params
##
## Required parameters:
##   table ... ref to metatable hash
## Optional parameters:
##   changes ... ref to changes record that will be updated with all changes
##   suffix .... add this string to the end of every form element name
##   record .... ref to a hash; fill in missing values from this record;
##               suffix not applied.
##
## Any param data not in the meta data table is ignored.  Hence, this function will
## pull only data relevant to the given table, and insert a row in the DB for it.
## If there is any data that should be put into the DB record that is not in
## param data, put it there first with param("the_column", $the_data)
##
## XXX:this does handle encrypting password fields!


sub doInsertFromParams
{
    my $argv = shift;
    argcvt($argv, ["table"], ['changes','suffix', 'join_table', 'join_id', 'record']);
    my $table = $$argv{'table'};
    my $record = $$argv{'record'};

    ## Is there a change object provided?

    my $changes;
    if ( exists $$argv{'changes'} ) {
        $changes = $$argv{'changes'};
    }
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";

    ##
    ## This record collects the changes in order to do the validation later
    ##
    my $rec;

    my $collist = "";
    my $vallist = "";
    my $sep = "";
    my $update = "";
    my $value;
    my $pkcol;
    foreach my $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'type'} eq "pk" ) {
            $pkcol = $tcol;
            next;
        }
        if ( $tcol->{'column'} eq "creation" || $tcol->{'column'} eq "modtime" ) {
            $collist .= "$sep$tcol->{'column'}";
            $vallist .= $sep . "NOW()";
            $sep = ",";

            ##
            ## This is not used for anything other that perhaps a table-specific validator
            ##

            my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
                $wday, $yday, $isdst) = localtime(time);
            my $dt = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                             1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds);
            $$rec{$$tcol{'column'}} = $dt;
            next;
        }
        if ( defined param($tcol->{'column'} . $suffix) ) {
          TYPE: {

              # multivalues scalars (sets)

              $$tcol{'type'} eq 'set' and do {
                  my @values = param($tcol->{'column'} . $suffix);
                  $value = join(",", @values);
                  last TYPE;
              };

              # single-valued scalars

              $$tcol{'type'} eq "time" and do {
                  my $hour = param($$tcol{'column'} . $suffix . "_hour");
                  $$rec{$$tcol{'column'} . "_hour"} = $hour;
                  my $minute = param($$tcol{'column'} . $suffix . "_minute");
                  $$rec{$$tcol{'column'} . "_minute"} = $minute;
                  my $ampm = param($$tcol{'column'} . $suffix . "_ampm");
                  $$rec{$$tcol{'column'} . "_ampm"} = $ampm;
                  $value = sprintf("%02d:%02d:00", $hour+12*($ampm), $minute);
                  last TYPE;
              };

              # password types

              $$tcol{'type'} eq "password" and do {
                  $value = Password::encrypt(param($tcol->{'column'} . $suffix));
                  last TYPE;
              };

              $value = param($tcol->{'column'} . $suffix);
          }; # TYPE
            $collist .= "$sep$tcol->{'column'}";
            $vallist .= "$sep" . SQLQuote($value);
            $sep = ",";

            $$rec{$$tcol{'column'}} = $value;

            if ( $changes && defined $value && $value ne "" ) {
                $changes->add({-table=>$table->{'table'},
                               -row=>0,                   # filled in later
                               -column=>$tcol->{'column'},
                               -secure=>$tcol->{'secure'},
                               -new=>$value,
                               -type=>"ADD",
                               -user=>Login::getLoginId(),
                               -join_table=>$$argv{'join_table'},
                               -join_id=>$$argv{'join_id'},
                               });
            }
        }
    }

    ##
    ## Add any elements from the default values record that are not already defined
    ##

    if ( defined $record ) {
        foreach my $k ( keys %$record ) {
            if ( !exists $$rec{$k} ) {
                $collist .= "$sep$k";
                $vallist .= "$sep" . SQLQuote($$record{$k});
                $sep = ",";
                $$rec{$k} = $$record{$k};
            }
        }
    }

    ##
    ## If there is a table-specific validator in the metadata table, call it
    ##

    my $valid = 1;
    if ( exists $table->{'preadd'} ) {
        $valid = &{$$table{'preadd'}}($rec);
    }

    if ( !$valid ) {
        return undef;
    }

    my $query = "INSERT INTO $table->{'table'} ( $collist ) VALUES ( $vallist )";
    SQLSend($query);
    SQLSend("Select LAST_INSERT_ID()");
    my $pk = SQLFetchOneColumn();
    
    $$rec{$pkcol->{'column'}} = $pk;

    $changes && $changes->updateAll({-row=>$pk});

    ## If there are any N-N rels, get their values and update them now

#    my $qq = new CGI;
#    my $paramref = $qq->Vars();
#    Utility::ObjDump($paramref);

    foreach my $tcol ( @{$table->{'rels'}} ) {
        if ( $tcol->{'type'} ne "N-N" ) {
            next;
        }
        my @values;
      WIDGET: {
          $tcol->{'widget'} eq LeftRightWidget::type() and do {
              @values = LeftRightWidget::getParamValue($tcol->{'hashkey'} . $suffix);
              last WIDGET;
          };
          $tcol->{'widget'} eq OptionMenu::type() and do {
              @values = param($tcol->{'hashkey'} . $suffix);
              last WIDGET;
          };
          !exists $tcol->{'widget'} and do {
              @values = param($tcol->{'hashkey'} . $suffix);
              last WIDGET;
          };
      };

        my $middletable = $tcol->{'table'};
        my $middletcol = findColumn({-table=>$middletable,
                                    -column=>$tcol->{'column'}[1]});
        my $righttable = $middletcol->{'values'}->{'table'};
        my $rightlabel = $middletcol->{'values'}->{'label'};
        my $leftkey = $tcol->{'column'}[0];
        my $rightkey = $tcol->{'column'}[1];

        foreach my $k ( @values ) {
            my $nnrec;
            $nnrec->{$leftkey} = $pk;
            $nnrec->{$rightkey} = $k;
            writeSimpleRecord({-table=>$middletable,
                               -record=>$nnrec});
            ## Reach to the rightmost table to get the label value
            if ( $changes ) {
                my $rightrecord = getRecordById({-table=>$righttable,
                                                 -id=>$k});
                $changes->add({-table=>$table->{'table'},
                               -row=>$pk,
                               -column=>$tcol->{'hashkey'},
                               -new=>$rightrecord->{$rightlabel},
                               -type=>"ADD",
                               -user=>Login::getLoginId(),
                               -join_table=>$$argv{'join_table'},
                               -join_id=>$$argv{'join_id'},
                               });
            }
        }
    }

    if ( exists $table->{'postadd'} ) {
        $valid = &{$$table{'postadd'}}($rec);
    }

    
    return $pk;
}

##
## doUpdateFromParams - update DB from form data
##
## required named parameters:
##    table .... table meta data of table being updated
##    record ... hash of current values, keys match DB columns
## optional named parameters:
##    changes .. a changes object to use to record changes
##    new ...... if defined, the new record is put into this
##    suffix ... optional suffix on form element names
##    pk ....... name of the primary key form parameter
##    debug .... enable debug prints to output
##

sub doUpdateFromParams
{
    my $argv = shift;

    argcvt($argv, ['table', 'record'], ['changes', 'new', 'suffix', 'pk', 'debug']);
    my $table = $$argv{'table'};
    my $rec = $$argv{'record'};
    my $debug = $$argv{'debug'};
    my $changes = 0;
    if ( exists $$argv{'changes'} ) {
        $changes = $$argv{'changes'};
    }
    my $newrec = 0;
    if ( exists $$argv{'new'} ) {
        $newrec = $$argv{'new'};
    }
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";

    ## This is due to the inconsistent naming of the primary key form parameter -
    ## This should be cleaned up in the code.

    my $pk;
    my $pkname;
    my $paramname;
    if ( defined $$argv{'pk'} && defined param($$argv{'pk'} . $suffix) ) {
        $pkname = $$argv{'pk'};
        $paramname = $$argv{'pk'};
    } elsif ( defined param("pk" . $suffix) ) {
        $pkname = "id";
        $paramname = "pk";
    } elsif ( defined param("id" . $suffix) ) {
        $pkname = "id";
        $paramname = "id";
    } else {
        Utility::redError("Neither pk nor id defined as a parameter");
        return;
    }
    $pk = param($paramname . $suffix);

    my $update = "";
    my $sep = "";
    my $mods = 0;
    my $newval;
    my $tcol;
    foreach $tcol ( @{$table->{'columns'}} ) {
        my $paramname = $tcol->{'column'} . $suffix;

        if ( $newrec && exists $$rec{$$tcol{'column'}} ) {
            $$newrec{$$tcol{'column'}} = $$rec{$$tcol{'column'}};
        }
        if ( $tcol->{'type'} eq "pk" ) {
            next;
        }
        if ( $tcol->{'column'} eq "modtime" ) {
            $update .= "$sep$tcol->{'column'} = NOW()";
            $sep = ",";
            next;
        }
        if ( defined param($paramname) ) {
            $newval = undef;
            ##
            ## Handle arrays and scalars differently
            ##
          TYPE: {
              
              ## array types:
              
              $$tcol{'type'} eq "set" and do {
                  $newval = join(",", param($$tcol{'column'} . $suffix));
                  last TYPE;
              };
              
              ## scalar types:
              
              $$tcol{'type'} eq "time" and do {
                  my $hour = param($$tcol{'column'} . $suffix . "_hour");
                  my $minute = param($$tcol{'column'} . $suffix . "_minute");
                  my $ampm = param($$tcol{'column'} . $suffix . "_ampm");
                  $newval = sprintf("%02d:%02d:00", $hour+12*($ampm), $minute);
                  last TYPE;
              };

              $$tcol{'type'} eq "password" and do {
                  my $formdata = param($$tcol{'column'} . $suffix);
                  if ( (defined $formdata && defined $$rec{$tcol->{'column'}} &&
                        $formdata ne $$rec{$tcol->{'column'}} ) ||
                       (defined $formdata != defined $$rec{$tcol->{'column'}})) {
                      $newval = Password::encrypt($formdata);
                  } else {
                      $newval = $$rec{$tcol->{'column'}};
                  }
                  last TYPE;
              };
              
              $newval = param($$tcol{'column'} . $suffix);
              
          }; #TYPE

            if ( $debug ) {
                print p("UpdateFromParams: \"$tcol->{'column'}\" old value=",
                        !exists $$rec{$tcol->{'column'}} ? "!exists" :
                        !defined $$rec{$tcol->{'column'}}?"undef": 
                        $$rec{$tcol->{'column'}},
                        " parameter=",
                        !defined param($paramname)?"undef": 
                        "\"" . param($paramname) . "\"" );
            }

            ##
            ## Problem: if the old value is NULL (undefined) and the parameter value
            ## is empty, then the DB shouldn't be changed.
            ##
            ## OLD              PARAMETER                 ACTION
            ## undefined        empty string              none
            ## undefined        string                    update
            ## defined          defined, same             none
            ## defined          defined, different        update

            if ( (!defined $$rec{$tcol->{'column'}} && $newval) ||
                 (defined $rec && $$rec{$tcol->{'column'}} ne $newval) ) {

                $newrec and $$newrec{$$tcol{'column'}} = $newval;
                $update .= "$sep$tcol->{'column'} = " . SQLQuote($newval);
                $sep = ",";
                $mods++;
                if ( $changes ) {  # add change to the audit table
                    $changes->add({-table=>$table->{'table'},
                                   -row=>"$pk",
                                   -column=>"$tcol->{'column'}",
                                   -secure=>$tcol->{'secure'},
                                   -type=>"CHANGE",
                                   -old=>$$rec{$tcol->{'column'}},
                                   -new=>$newval,
                                   -user=>Login::getLoginId(),
                               });
                }
            }
        }
    }

    # Write the table updates to the DB

    if ( $mods > 0 ) {
        my $query = "UPDATE $table->{'table'} SET $update WHERE $pkname = " . SQLQuote($pk);
        SQLSend($query);
    }


    ## If there are any N-N rels, get their values and update them now
    ## N-N rels can have a "widget" type of LeftRight and if so, the
    ## data is passed in as a comma separated scalar

    foreach $tcol ( @{$table->{'rels'}} ) {
        if ( $tcol->{'type'} ne "N-N" ) {
            next;
        }

        my $paramname = $tcol->{'hashkey'} . $suffix;

        if ( not defined param($paramname) ) {
            next;
        }

        my @new_ids;
      WIDGET: {
          $tcol->{'widget'} eq LeftRightWidget::type() and do {
              @new_ids = LeftRightWidget::getParamValue($paramname);
              last WIDGET;
          };
          $tcol->{'widget'} eq OptionMenu::type() and do {
              @new_ids = param($paramname);
              last WIDGET;
          };
          !exists $tcol->{'widget'} and do {
              @new_ids = param($paramname);
              last WIDGET;
          };
          Utility::redError("Invalid 'widget' type in $table->{'table'} column $tcol->{'hashkey'}");
      };

        my @old_ids = getRecordsMatch({-table=>$tcol->{'table'},
                                   -value=>$rec->{'id'},
                                   -column=>$tcol->{'column'}[0],
                                   -dojoin=>0});
 
        if ( $debug ) {
            print "UpdateFromParams: \"$tcol->{'hashkey'}\" ",
            "old ids = ", "<pre>", Dumper(\@old_ids),"</pre>",
            "new ids = ", "<pre>", Dumper(\@new_ids),"</pre>", br;
        }

        my %adds;
        my %removes;
        foreach my $uid ( @new_ids ) {
            $adds{$uid} = 1;
        }
        foreach my $ref ( @old_ids ) {
            my $tmp_uid = $ref->{$tcol->{'column'}[1]};
            if ( exists $adds{$tmp_uid} ) {
                delete $adds{$tmp_uid};
            } else {
                $removes{$tmp_uid} = 1;
            }
        }

        my $middletable = $tcol->{'table'};
        my $middletcol = findColumn({-table=>$middletable,
                                    -column=>$tcol->{'column'}[1]});
        my $righttable = $middletcol->{'values'}->{'table'};
        my $rightrecord;
        my $rightlabel = $middletcol->{'values'}->{'label'};

        my $leftkey = $tcol->{'column'}[0];
        my $rightkey = $tcol->{'column'}[1];

        my $assoc_rec;
        foreach my $k ( keys %adds ) {
            $assoc_rec->{$leftkey} = $pk;
            $assoc_rec->{$rightkey} = $k;
            writeSimpleRecord({-table=>$middletable,
                               -record=>$assoc_rec});
            if ( $changes ) {
                $rightrecord = getRecordById({-table=>$righttable,
                                                 -id=>$k});
                $changes->add({-table=>$table->{'table'},
                               -row=>$pk,
                               -column=>$tcol->{'hashkey'},
                               -new=>$rightrecord->{$rightlabel},
                               -type=>"ADD",
                               -user=>Login::getLoginId()});
            }

        }
        foreach my $rem_k ( keys %removes ) {
            $assoc_rec->{$leftkey} = $pk;
            $assoc_rec->{$rightkey} = $rem_k;
            deleteSimpleRecord({-table=>$middletable,
                                -record=>$assoc_rec});
            if ( $changes ) {  # add change to the audit table
                $rightrecord = getRecordById({-table=>$righttable,
                                                 -id=>$rem_k});
                $changes->add({-table=>$table->{'table'},
                               -row=>"$pk",
                               -column=>"$tcol->{'hashkey'}",
                               -type=>"REMOVE",
                               -old=>$rightrecord->{$rightlabel},
                               -user=>Login::getLoginId(),
                           });
            }
        }
    }

    if ( exists $table->{'postupdate'} ) {
        &{$$table{'postupdate'}}($rec);
    }

}






##
## COMMON ENTRY/EDIT/DISPLAY SUBROUTINES
##

sub doEditTable
{
    my $argv = shift;
    argcvt($argv, ['table'], []);
    my $table = $$argv{'table'};

    my $result = "";
    my $tcol;
    
    param("op", "editdelete");
    $result .= hidden({-name=>"op", -value=>"editdelete"}) . "\n";
    $result .= start_table({-border=>"1", -cellspacing=>"0", -cellpadding=>"4"}) . "\n";

    ## Form the heading row of PK and buttons followed by the columns
    ## of the table.

    $result .= start_Tr . "\n";
    $result .= td(b("ID")) . td(b("Edit")) . td(b("Delete")) . "\n";
    foreach $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'private'} ) {
            next;
        }
        if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            next;
        }
        $result .= td(b($tcol->{'heading'})) . "\n";
    }


    my $columns = "";
    my $sep = "";
    my $pk;
    foreach $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'private'} ) {
            next;
        }
        if ( exists $tcol->{'binary'} && $tcol->{'binary'} ) {
            next;
        }
        $columns = "$columns$sep$tcol->{'column'}";
        $sep = ",";
        if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            $pk = $tcol;
        }
    }

    ## Fetch all of the entries from this table

    my $query = "SELECT $columns from $table->{'table'}";
    if ( exists $table->{'order'} ) {
        $query .= " ORDER BY $table->{'order'}";
    }
    
    SQLSend($query);
    my @results;
    my @allresults;
    while ( @results = SQLFetchData() ) {
        push @allresults, [ @results ];
    }

    ## Create the rows of the edit table.
    ## The Edit and Delete buttons have names of
    ##    edit%d
    ##    delete%d
    ## where %d is the PK of the entry.

    foreach my $r ( @allresults ) {
        my %values;
        foreach $tcol ( @{$table->{'columns'}} ) {
            $values{$tcol->{'column'}} = shift @$r;
        }
        
        $result .= start_Tr;
        my $pkvalue = $values{$pk->{'column'}};
        $result .= td($pkvalue) .
            td(submit({-name=>"edit$pkvalue", -label=>"Edit"}))  . "\n". 
            td(submit({-name=>"delete$pkvalue", -label=>"Delete"})) . "\n";
        foreach $tcol ( @{$table->{'columns'}} ) {
            if ( $tcol->{'private'} ) {
                next;
            }
            my $value = $values{$tcol->{'column'}};
            if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
                next;
            }

            ## Format the current value of this column in this row.

            if ( !exists $tcol->{'type'} ) {
                $result .= td($value) . "\n";
            } else {
              SW: {
                  exists $tcol->{'binary'} && $tcol->{'binary'} and do {
                      $result .= td("(binary data)") . "\n";
                      last SW;
                  };
                  $tcol->{'type'} eq "url" and do {
                      $result .= td($value ? a({-href=>"$value"},"link") : "&nbsp;") . "\n";
                      last SW;
                  };
                  $tcol->{'type'} eq "email" and do {
                      $result .= td($value ? emailLink($value) : "&nbsp;") . "\n";
                      last SW;
                  };

                  ## if this column is a foreign key to an external
                  ## table, get the designated 'label' field of the
                  ## row this entry points to.
                  ## XXX: this is a non-caching fetch! (3/29/05 changing to converters)

                  $tcol->{'type'} eq "fk" and do {
                      if ( $value ) {
                          my $displayable = Converter::convertToDisplayable({
                              -table=>$tcol->{'values'}{'table'},
                              -column=>$tcol->{'values'}{'pk'},   ### XXX WRONG COLUMN???
                              -value=>$value,
                              -label=>$tcol->{'values'}{'label'},
                          });
                          $result .= td($displayable) . "\n";
#                          $result .= td(getValueMatch({
#                              -table=>$tcol->{'values'}{'table'},
#                              -column=>$tcol->{'values'}{'pk'},
#                              -equals=>$value,
#                              -return=>$tcol->{'values'}{'label'},
#                          })) . "\n";
                      } else {
                          $result .= td("null") . "\n";
                      }
#                      $result .= td($value) . "\n";
                      last SW;
                  };
                  $result .= td($value ? $value : "&nbsp;") . "\n";
              };
            }
        }
        $result .= end_Tr . "\n";
    }


    
    $result .= end_table . "\n";
    return $result;
}

##
## doEntryForm - create a record entry form
##
## Required parameters -
##    table .... ref to the table metadata hash
##
## Optional parameters -
##    suffix .... add this string to the end of every form element name
##    hide ...... an array of column names to omit from the entry form
##    record .... if columns are hidden, this record specifies their default
##                values.  This happens AFTER and setdefaults hook
##    nocolor ... if non-zero, omit the alternating green/white background
##    clientonchange .. hash of name=>javascript.  The javascript becomes the
##                onchange for the hash key element.
##

sub doEntryForm 
{
    my $argv = shift;
    my $args;
    my $tcol;

    argcvt($argv, ["table"],
           ['hide', 'record', 'suffix', 'nocolor', 'back', 'clientonchange']);
    my $table = $$argv{'table'};
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";
    my $nocolor = $$argv{'nocolor'};
    my $clientonchange = $$argv{'clientonchange'};

    #  %hidden is a hash of hidden column names

    my $hide = $$argv{'hide'};
    my %hidden;
    foreach my $h ( @$hide ) {
        $hidden{$h} = 1;
    }

    ##
    ## Manage default values for initial entry:
    ##   The supplied "record" parameter holds default values
    ##   for everything except globally hidden columns.
    ##   For other columns, take the supplied "record" values
    ##   if provided, otherwise take the programmatically
    ##   defined defaults from a metatdata "setdefaults"
    ##   hook function, otherwise set no default value.
    ##
    ## The two sources are merged into a single "defaults"
    ##   record honoring this precedence.
    ##

    my $provided = $$argv{'record'};

    my %setdefaults;
    if ( exists $table->{'setdefaults'} ) {
        &{$table->{'setdefaults'}}(\%setdefaults);
    }
    my $defaults;
    foreach my $k1 ( keys %setdefaults ) {
        $$defaults{$k1} = $setdefaults{$k1};
    }
    foreach my $k2 ( keys %$provided ) {
        $$defaults{$k2} = $$provided{$k2};
    }
    my $result = start_table({-border=>"0"}) . "\n";
    my $row = 0;  # used to determine row color

    my $class;
    foreach $tcol ( @{$table->{'columns'}} ) {

        # Color every other row differently

        if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            next;
        }
        
        ## Only admins can set secure fields to something other
        ## than the default
        
        if ( $tcol->{'secure'} eq 'admin' && !Login::isAdmin() ) {
            next;
        }
        if ( $tcol->{'secure'} eq 'seesalary' && !Login::canSeeSalary() ) {
            next;
        }

 
        ##
        ## If this is a globally hidden column, skip it
        ## If it is locally hidden (this call only) and has a value in
        ## the record of defaults, insert a hidden form value
        ##

#        if ( exists $$tcol{'hide'} && $$tcol{'hide'} ) {
#            if ( defined $provided && exists $$provided{$$tcol{'column'}} ) {
#                $result .= hidden({-name=>$$tcol{'column'} . $suffix,
#                                   -default=>$$provided{$$tcol{'column'}}});
#            }
#            next;
#        }
 
        if ( ( exists $$tcol{'hide'} && $$tcol{'hide'} ) ||
             exists $hidden{$tcol->{'column'}} ) {
            if ( defined $defaults && exists $$defaults{$$tcol{'column'}} ) {
                $result .= hidden({-name=>$$tcol{'column'} . $suffix,
                                   -default=>$$defaults{$$tcol{'column'}}}) . "\n";
            }
            next;
        }

        ## start a new row in the entry table followed by the label column text

        $row++;
        $class = $row%2 ? "odd" : "even" ;

        ## Create the table cell containing the label cell

        $args = {
            -align=>"right",
            -valign=>"middle",
            -nowrap=>"1",
        };
        !$nocolor and $$args{'-class'} = $class;
        $result .= start_Tr() . "\n" .
            td($args, b("$tcol->{'heading'}: ")) . "\n";

        ## Start the cell for the form element.
        ## If there is no help field, allow it to span two columns
        ## This cell contains an inner div that holds all of the
        ## content so that it can be turned on an off if it is a variant
        ## field.

        $args = {
            -valign => "top",
            };
        !$nocolor and $$args{'-class'} = $class;
        !exists $tcol->{'help'} and $$args{'-colspan'} = "2";
        my $divname = "div_$theForm"  . "_$$tcol{'column'}$suffix";

        $result .= start_td($args) . "\n";

        $result .= start_div({-id=>$divname});

        ## Fill in the form element widget

        my $sfe_args = {
            -table=>$table,
            -column=>$tcol,
            -record=>$defaults,
            -form=>$theForm,
            -div=>$divname,
            -suffix=>$suffix,
            -back=>$$argv{'back'},
        };
        if ( $clientonchange && $clientonchange->{$tcol->{'column'}} ) {
            $sfe_args->{'-clientonchange'} =  $clientonchange->{$tcol->{'column'}};
#            Utility::ObjDump([keys %$sfe_args]);
        };

        $result .= Layout::doSingleFormElement($sfe_args);
        $result .= end_div;
        $result .= end_td() . "\n";

        ## If there is a help field, place it in the third column

        if ( exists $tcol->{'help'} ) {
            $args = {};
            !$nocolor and $$args{'-class'} = $class;
            $result .= td($args, $tcol->{'help'} ) . "\n";
        }
        $result .=  end_Tr();
    }

    ## Now add any N-N rels

    foreach $tcol ( @{$table->{'rels'}} ) {
        if ( exists $tcol->{'type'} && $tcol->{'type'} ne "N-N" ) {
            next;
        }
        
        $row++;
        $class = $row%2 ? "odd" : "even" ;
        
        # Start the form row
        
        $args = {-align=>"right", -valign=>"top", -nowrap=>"1"};
        !$nocolor and $$args{'-class'} = $class;
        
        $result .= start_Tr() .
            td($args, b("$tcol->{'heading'}: ")) . "\n";
        
        ## start the form element column.
        ## If there is no help field, allow it to span two columns
        
        $args = {-valign=>"top",};
        !$nocolor and $$args{'-class'} = $class;
        if ( !exists $tcol->{'help'} ) {
            $$args{'-colspan'} = "2";
        }
        $result .= start_td($args) . "\n";
        
        my $nntable = $tcol->{table};
        my $othercolumn = $tcol->{'column'}[1];
        my $menutable;
        my $label;
        # Find the outbound column in the association table table to get to the table on the other side
        foreach my $ocol ( @{$nntable->{'columns'}} ) {
            if ( $ocol->{'column'} eq $othercolumn ) {
                $menutable = $ocol->{'values'}{'table'};
                $label = $ocol->{'values'}{'label'};
                last;
            }
        }
        if ( $menutable ) {
            $args = {-table => $menutable,
                        -column => $label,
                        -multiple=>"1",
                        -name => $tcol->{'hashkey'},
                        -suffix=>$suffix,
                    };
            Layout::addStatusCheck({-args=>$args});
            # 2/1/2005: Added left/right widget support for multiselect N-N rels
          WIDGET:{
              $tcol->{'widget'} eq LeftRightWidget::type() and do {
                  $args->{'form'} = $theForm;
                  $result .= LeftRightWidget::widget($args);
                  last WIDGET;
              };
              ($tcol->{'widget'} eq OptionMenu::type() || !exists $tcol->{'widget'}) and do {
                  $args->{'form'} = $theForm;
                  $result .= OptionMenuWidget::widget($args);
                  last WIDGET;
              };
              $result .= Utility::redError("Invalid widget type \"$tcol->{'widget'}\"");
          };
        } else {
            $result .= "N-N REL ERROR" . "\n";
        }
        $result .= end_td() . "\n";
        
        ## If there is a help field, place it in the third column
        
        if ( exists $tcol->{'help'} ) {
            $args = {};
            !$nocolor and $$args{'-class'} = $class;
            $result .= td($args, $tcol->{'help'} ) . "\n";
        }
        $result .=  end_Tr() . "\n";
        
    }

    $result .= end_table() . "\n";
    
    return $result;
}

##
## doHiddenForm - Put values of a DB record into hidden parameters
##
## Required parameters -
##    table .... ref to the table metadata hash
##
## Optional parameters -
##    suffix .... add this string to the end of every form element name
##    hide ...... an array of column names to omit from the output form
##    record .... the values of the record
##

sub doHiddenForm 
{
    my $argv = shift;
    my $args;

    argcvt($argv, ["table", 'record'], ['hide', 'suffix']);
    my $table = $$argv{'table'};
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";

    #  %hidden is a hash of hidden column names

    my $hide = $$argv{'hide'};
    my %hidden;
    foreach my $h ( @$hide ) {
        $hidden{$h} = 1;
    }
    my $values = $$argv{'record'};
    
    my $result = "";

    foreach my $tcol ( @{$table->{'columns'}} ) {

        ## Skip those columns lised in the "hide" array

        if ( exists $hidden{$tcol->{'column'}} ) {
            next;
        }
        if ( defined $values && exists $$values{$$tcol{'column'}} ) {
            $result .= hidden({-name=>$$tcol{'column'} . $suffix,
                               -default=>$$values{$$tcol{'column'}}}) . "\n";
        }
    }

    return $result;
}

## doEditForm - create and return the HTML for a record edit form
##
## Required parameters:
##    table .... ref to a table metadata hash
##    record ... ref to the record to edit
##
## Optional parameters:
##    hide ..... ref to an array of column names to hide on the form
##    suffix ... suffx placed on the end of every form element name.
##    back ..... URL to return to if need to link off somehere else
##               temporarily, e.g. to edit a referenced table.
##    help ..... ref to a hash keyed by column names, containing custom "help" strings
##
## By default, the form element names are identical to the column names
## in the metadata hash.  If -suffix is provided, this string is added
## to each form element name.  For example, a column named "description"
## would have a form element named "description" but if -suffix=>"_1" is
## provided, then the form element name will be "description_1"

sub doEditForm
{
    my $argv = shift;
    argcvt($argv,
           ['table', 'record'],
           ['hide', 'suffix', 'back','help', 'debug']);
    my $table = $$argv{'table'};
    my $values = $$argv{'record'};
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";
    my $debug = $$argv{'debug'};
    my $tcol;

    my $hide = $$argv{'hide'};
    my %hidden;
    foreach my $h ( @$hide ) {
        $hidden{$h} = 1;
    }

    my $result = start_table({
        -border=>"0",
        -cellpadding=>4,
        -cellspacing=>"0",
    });

    foreach $tcol ( @{$table->{'columns'}} ) {
        if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            next;
        }

        # Only admins can change secure fields

        if ( $tcol->{'secure'} eq 'secure' && !Login::isAdmin() ) {
            next;
        }
        if ( $tcol->{'secure'} eq 'seesalary' && !Login::canSeeSalary() ) {
            next;
        }

        # Skip over hidden fields - both those marked as hidden in the
        # table metadata and those marked to hide on this call only.
        ## XXX: Some hidden columns should be editable by the admin user.

        if ( exists $$tcol{'hide'} && $$tcol{'hide'} ) { #global
            next;
        }
        if ( exists $hidden{$tcol->{'column'}} ) { #per call
            if ( exists $$values{$$tcol{'column'}} ) {
                $result .= hidden({
                    -name=>$$tcol{'column'} . $suffix,
                    -default=>$$values{$$tcol{'column'}},
                }) . "\n";
            }
            next;
        }

        # Start one row of the edit table

        $result .= start_Tr() . "\n";

        # Create the cell for the label

        $result .= td({-align=>"right"},b("$tcol->{'heading'}: ")) . "\n";

        ## Create the cell for the value widget
        ## The contents of this cell are wrapped in a div so that its visibility
        ## can be controlled if it is a variant.
        ## also, could be a customer help string here passed in

        if ( exists $tcol->{'help'} ||
             (exists $$argv{'help'} and exists $$argv{'help'}->{$tcol->{'column'}})) {
            $result .= start_td({-valign=>"top"}) . "\n";
        } else {
            $result .= start_td({-valign=>"top", -colspan=>"2"}) . "\n";
        }
        $result .= start_div({-id=>"div_$theForm" . "_$$tcol{'column'}$suffix"}) . "\n";

        $result .= Layout::doSingleFormElement({
            -table=>$table,
            -column=>$tcol,
            -record=>$values,
            -suffix=>$suffix,
            -back=>$$argv{'back'},
            -debug=>$debug,
        });
        $result .= end_div() . "\n";
        $result .= end_td() . "\n";

        ## If there is a help field, place it in the third column

        if ( exists $$argv{'help'} && exists $$argv{'help'}->{$tcol->{'column'}}) {
            $result .= td($$argv{'help'}->{$tcol->{'column'}});
        } elsif ( exists $tcol->{'help'} ) {
            $result .= td($tcol->{'help'} ) . "\n";
        }

        $result .= end_Tr() . "\n";
    }

    ## Now add any N-N rels
    ## N-N rels can have LeftRight widgets

    foreach $tcol ( @{$table->{'rels'}} ) {
        if ( exists $tcol->{'type'} && $tcol->{'type'} ne "N-N" ) {
            next;
        }
        
        $result .= start_Tr() .
            td({
                -align=>"right",
                -valign=>"top",
                -nowrap=>"1",
            },
               b("$tcol->{'heading'}: ")) . "\n";

        ## start the form element column.
        ## If there is no help field, allow it to span two columns

        if ( exists $tcol->{'help'} ||
             (exists $$argv{'help'} && exists $$argv{'help'}->{$tcol->{'column'}})) {
            $result .= start_td({-valign=>"top"}) . "\n";
        } else {
            $result .= start_td({-valign=>"top", -colspan=>"2"}) . "\n";
        }
#--------------------------------------------
        my @nnrecs = getRecordsMatch({-table=>$tcol->{'table'},
                                   -value=>$values->{'id'},
                                   -column=>$tcol->{'column'}[0],
                                   -dojoin=>1});
        my $middletcol = findColumn({-table=>$tcol->{'table'},
                                    -column=>$tcol->{'column'}[1]});
        my $jointable = $middletcol->{'values'}->{'table'};
        my $joinlabel = $middletcol->{'values'}->{'label'};
        my $field = $tcol->{'column'}[1] . "." . $joinlabel;
        my @defaults;

        foreach my $nnrec ( @nnrecs ) {
            my $id = $nnrec->{$tcol->{'column'}[1]};
            push @defaults, $id;
        }
        my $args = {-table => $jointable,
                    -column => $joinlabel,
                    -multiple=>"1",
                    -name => $tcol->{'hashkey'},
                    -default=>\@defaults,
                    -suffix=>$suffix,
                    -size=>$tcol->{'size'},
                };
        Layout::addStatusCheck({-args=>$args});

        # 2/1/2005: Added left/right widget support for multiselect N-N rels
      WIDGET:{
          $tcol->{'widget'} eq LeftRightWidget::type() and do {
              $args->{'form'} = $theForm;
              $result .= LeftRightWidget::widget($args);
              last WIDGET;
          };
          ($tcol->{'widget'} eq OptionMenu::type() || !exists $tcol->{'widget'}) and do {
              $args->{'form'} = $theForm;
              $result .= OptionMenuWidget::widget($args);
              last WIDGET;
          };
          $result .= Utility::redError("Invalid widget type \"$tcol->{'widget'}\"");
      };

#--------------------------------------------
        $result .= end_td() . "\n";

        ## If there is a help field, place it in the third column

        if ( exists $$argv{'help'} && exists $$argv{'help'}->{$tcol->{'column'}}) {
            $result .= td($$argv{'help'}->{$tcol->{'column'}});
        } elsif ( exists $tcol->{'help'} ) {
            $result .= td($tcol->{'help'} ) . "\n";
        }
        $result .=  end_Tr() . "\n";
    }

 
    $result .= end_table() . "\n";

    return $result;
}


sub doSingleFormElement
{
    my $argv = shift;
    argcvt($argv,
           ['table', 'column'],
           ['record', 'suffix', 'onchange', 'back', 'form', 'div', 'debug', 'id',
           'clientonchange']);
    my $table = $$argv{'table'};
    my $column = $$argv{'column'};
    my $values = $$argv{'record'};
    my $form = $$argv{'form'};
    my $div = $$argv{'div'};
    my $argv_id = $$argv{'id'};
    my $debug = $$argv{'debug'};
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";
    my $clientonchange = $$argv{'clientonchange'};

    my $tcol = ref($$argv{'column'}) eq "HASH" ?
        $$argv{'column'} :
        findColumn({-table=>$table,
                            -column=>$column});

    my $paramname = $$tcol{'column'} . $suffix;
    my $args;
    my $id;
    if ( $form ) {
        $id= "id_$theForm"  . "_$paramname";
    }

    my $result = "";

    ## What happens next depends on the type of element

  SW:{

      ## TODO: Add -id everywhere
      
      ## ENUM type
      ## If this element is a part of a group, then need to
      ## augment the onchange tag to contain a call to the
      ## javascript item that makes visible or hides the variant
      ## form element.

      $tcol->{'type'} eq "enum"  and do {
          if ( $tcol->{'nullable'} ) {
              $args = {-table=>$table,
                          -column=>$tcol->{'column'},
                          -null=>$::MENU_NONE,
                           -suffix=>$suffix,
                          -onchange=>$$argv{'onchange'},
                      };
              if ( defined $values ) {
                  $$args{'-default'} = $values->{$tcol->{'column'}};
              }
              Layout::addStatusCheck({
                  -args=>$args,
                  -default=>$$args{'-default'},
              });
              Layout::addVariant({
                  -table=>$table,
                  -column=>$tcol,
                  -args=>$args,
              });
              $result .= PulldownMenu($args);
              $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});

          } else {
              $args = {
                  -table=>$table,
                  -column=>$tcol->{'column'},
                      -suffix=>$suffix,
                  -onchange=>$$argv{'onchange'},
              };
              if ( defined $values ) {
                  $$args{'-default'} = $values->{$tcol->{'column'}};
              }
#              print font({-color=>"#0000AA"}, "pre-addVariant: ", $$args{'-onchange'}), br;
              Layout::addVariant({
                  -table=>$table,
                  -column=>$tcol,
                  -args=>$args,
              });
#              print font({-color=>"#0000AA"}, "pre-addStatusCheck: ", $$args{'-onchange'}), br;
              Layout::addStatusCheck({
                  -args=>$args,
                  -default=>$$args{'-default'},
              });
#              print font({-color=>"#0000AA"}, "post-addStatusCheck: ", $$args{'-onchange'}), br;
              $result .= PulldownMenu($args);

              $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});

          }
          last SW;
      };

      ##
      ## SET
      ##

      $tcol->{'type'} eq "set" and do {
          my @vals = split(",", $values->{$tcol->{'column'}});
          $args = {
              -table=>$table,
              -column=>$tcol->{'column'},
              -multiple=>1,
              -suffix=>$suffix,
              -size=>$tcol->{'size'},
          };
          if ( defined $values ) {
              $$args{'-default'} = \@vals;
          }
          $$args{'-form'} = $theForm;
          $result .= OptionMenuWidget::widget($args);
          last SW;
      };

      ##
      ## EMAIL
      ##

      $tcol->{'type'} eq "email" and do {
          $args = {
              -name=>$paramname,
              -size=>"32",
              -onchange=>$$argv{'onchange'},
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});
          $result .= textfield($args) . "\n";
          last SW;
      };

      ##
      ## FLOAT
      ##

      $tcol->{'type'} eq "float" and do {
          $args = {
              -name=>"$tcol->{'column'}$suffix",
              -size=>"8",
              -onchange=>$$argv{'onchange'},
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }

          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});

          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });

          $result .= textfield($args) .  "\n";
          last SW;
      };

      ##
      ## TIME
      ##

      $tcol->{'type'} eq "time" and do {
          if ( defined $values ) {
              $result .= hidden({-name=>$paramname,
                                 -default=>$values->{$tcol->{'column'}}}) . "\n";
          }
          my @pieces = split(":", $values->{$tcol->{'column'}});

          my $hour = $pieces[0]>12 ? $pieces[0]-12 : $pieces[0];
          $args = {-name=>$paramname . "_hour",
                      -size=>"3",
                      -onchange=>$$argv{'onchange'}
                  };
          if ( defined $values ) {
              $$args{'-default'} = $hour;
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $result .= textfield($args) . "\n";

          $args = {-name=>$paramname  . "_minute",
                      -size=>"3",
                   -onchange=>$$argv{'onchange'}
               };
          if ( defined $values ) {
              $$args{'-default'} = $pieces[1];
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $result .= textfield($args) . "\n";

          $args = {-name=>$paramname  . "_ampm",
                   -values=>[0,1],
                   -labels=>{'0'=>"a.m.",
                             '1'=>"p.m."},
                   -onchange=>$$argv{'onchange'},
               };
          if ( defined $values ) {
              $$args{'-default'} = $pieces[0]>12 ? 1 : 0;
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
              -name => $paramname,
          });
          $result .= popup_menu($args) . "\n";
          last SW;
      };
      
      ##
      ## DATETIME
      ##

      $tcol->{'type'} eq "datetime" and do {
#          $result .= DateTime::FormElement({
#              -column => $tcol,
#              -name => $paramname,
#              -default => $values->{$tcol->{'column'}},
#              -onchange => $$argv{'onchange'},
#              -id => $id,
#          });
          if ( ! $values->{$tcol->{'column'}} ) {
              my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
                  $wday, $yday, $isdst) = localtime(time);
              $values->{$tcol->{'column'}} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                                                     1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds);
          }
          my $args = {
              -name=>$paramname ,
              -size=>$tcol->{'width'},
              -onchange=>$$argv{'onchange'},
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $result .= textfield($args) . "\n";

          last SW;
      };

      ##
      ## DATE
      ##

      $tcol->{'type'} eq "date" and do {
          $args = {
              -name=>$paramname,
              -size=>12,
              -onchange=>$$argv{'onchange'},
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});
          $result .= textfield($args) .
              a({-href=>"javascript:show_calendar('$form.$$tcol{'column'}');"},
                img({-src=>"images/show_calendar.gif", -border=>"0"})) .
                 "\n";
          last SW;
      };

      ##
      ##    TEXT
      ##

      $tcol->{'type'} eq "text" and do {
          $args = {
              -name=>$paramname ,
              -size=>$tcol->{'width'},
              -onchange=>$$argv{'onchange'}
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});
          $result .= textfield($args) . "\n";
          last SW;
      };

      ##
      ##    TEXT
      ##

      $tcol->{'type'} eq "password" and do {
          $args = {
              -name=>$paramname ,
              -size=>$tcol->{'width'},
              -onchange=>$$argv{'onchange'}
          };
          if ( defined $values ) {
              $$args{'-default'} = $values->{$tcol->{'column'}};
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});
          $result .= password_field($args) . "\n";
          last SW;
      };

      ##
      ## BIGTEXT
      ##

      $tcol->{'type'} eq "bigtext" and do {
          $args = {
              -name=>$paramname ,
              -rows => defined $$tcol{'rows'} ? $$tcol{'rows'} : "20",
              -columns => defined $$tcol{'columns'} ? $$tcol{'columns'} : "80",
              -onchange=>$$argv{'onchange'},
          };
          if ( defined $values ) {
              $$args{'-default'} =  $values->{$tcol->{'column'}};
          }
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addVariant({
              -table=>$table,
              -column=>$tcol,
              -args=>$args,
          });
          Layout::addStatusCheck({
              -args=>$args,
              -default=>$$args{'-default'},
          });
          $result .= textarea($args) . "\n";
          last SW;
      };

      ##
      ## FOREIGN KEY
      ##

      $tcol->{'type'} eq "fk" and do {
          $debug && print "$tcol->{'column'}", br; #XXX
          if ( $tcol->{'nullable'} ) {
              $args = {
                  -table=>$tcol->{'values'}{'table'},
                  -column=>$tcol->{'values'}{'label'},
                  -null=>$::MENU_NONE,
                  -name=>$tcol->{'column'},
                  -suffix=>$suffix,
                  -onchange=>$$argv{'onchange'},
                  -clientonchange=>$clientonchange,
              };
              if ( $argv_id ) {
                  $$args{'id'} = $argv_id;
              }

              if ( defined $values  && exists $values->{$tcol->{'column'}} ) {
                  $$args{'-default'} = $values->{$tcol->{'column'}};
                  Layout::addVariant({
                      -table=>$table,
                      -column=>$tcol,
                      -args=>$args,
                  });
                  Layout::addStatusCheck({
                      -args=>$args,
                      -default=>$$args{'-default'},
                  });
                  Layout::addOnChange({
                      -table=>$table,
                      -column=>$tcol,
                      -args=>$args,
                      -clientonchange=>$clientonchange,
                  });
              } else {
                  Layout::addVariant({
                      -table=>$table,
                      -column=>$tcol,
                      -args=>$args,
                  });
                  Layout::addStatusCheck({
                      -args=>$args,
                      -default=>"0",
                  });
                  Layout::addOnChange({
                      -table=>$table,
                      -column=>$tcol,
                      -args=>$args,
                      -clientonchange=>$clientonchange,
                  });
              }
              ## HERE - we have to allow for inactive items, in some cases.  XXX

              $result .= PulldownMenu($args) . "\n";
              $result .= Layout::addFkEdit({
                  -table=>$table,
                  -column=>$tcol,
                  -back=>$$argv{'back'},
              });
          } else {
              $args = {
                  -table=>$tcol->{'values'}{'table'},
                  -column=>$tcol->{'values'}{'label'},
                  -name=>$tcol->{'column'},
                  -suffix=>$suffix,
                  -onchange=>$$argv{'onchange'},
                  -clientonchange=>$clientonchange,
              };
              if ( defined $values ) {
                  $$args{'-default'} = $values->{$tcol->{'column'}};
              }
              Layout::addVariant({
                  -table=>$table,
                  -column=>$tcol,
                  -args=>$args,
              });
              Layout::addStatusCheck({
                  -args=>$args,
                  -default=>$$args{'-default'},
              });
              Layout::addOnChange({
                  -table=>$table,
                  -column=>$tcol,
                  -args=>$args,
                  -clientonchange=>$clientonchange,
                                  });
              $result .= PulldownMenu($args) . "\n";
              $result .= Layout::addFkEdit({
                  -table=>$table,
                  -column=>$tcol,
                  -back=>$$argv{'back'},
              });
          }
          $validatorScript .= formValidate({-column=>$tcol,-suffix=>$suffix});
          last SW;
      };

      ## Default type

      $args = {
          -name=>$paramname,
          -size=>$tcol->{'width'},
          -onchange=>$$argv{'onchange'},
      };
      if ( defined $values ) {
          $$args{'-default'} = $values->{$tcol->{'column'}};
      }
      Layout::addVariant({
          -table=>$table,
          -column=>$tcol,
          -args=>$args,
      });
      Layout::addStatusCheck({
          -args=>$args,
          -default=>$$args{'-default'},
      });
      $validatorScript .= formValidate({
          -column=>$tcol,
          -suffix=>$suffix,
      });
      $result .= textfield($args) . "\n";
  };
    return $result;
}

sub addFkEdit
{
    my $argv = shift;
    argcvt($argv, ['column'], ['table', 'back']);
    my $tcol = $$argv{'column'};
    if ( ref($tcol) ne "HASH" ) {
        $tcol = findColumn({-table=>$$argv{'table'},
                            -column=>$$argv{'column'}});
    }
    if ( !$$tcol{'editable'} ) {
        return "";
    }

    my $back =  $$argv{'back'} ? $$argv{'back'} : self_url();
    my $othertable = $$tcol{'values'}->{'table'};
    my $escback = CGI::escape($back);
    return a({
        -href=>"manage.cgi?table=$$othertable{'table'};back=$escback",
    }, "Edit $$othertable{'table'} list");
}

sub formValidate
{
    my $argv = shift;
    argcvt($argv, ['column'], ['table', 'suffix']);
    my $tcol = $$argv{'column'};
    if ( ref($tcol) ne "HASH" ) {
        $tcol = findColumn({-table=>$$argv{'table'},
                            -column=>$$argv{'column'}});
    }
    my $suffix = $$argv{'suffix'} ? $$argv{'suffix'} : "";
    my $vstr = "";
    if ( exists $tcol->{'validators'} ) {
        foreach my $v ( @{$tcol->{'validators'}} ) {
            $vstr .= "v.add(\"$tcol->{'column'}$suffix\", " .
                "\"$tcol->{'heading'}\", " .
                "\"$v->[0]\"";
            if ( scalar @$v > 1 ) {
                $vstr .= ", [" . join(",", @{$v->[1]}) . "]";
            }
            $vstr .= ");\n";
        }
        if ( exists $tcol->{'validate'}->{'range'} ) {
            $vstr .= "v.add(\"$tcol->{'column'}$suffix\", \"$tcol->{'heading'}\", \"range\", [" .
                $tcol->{'validate'}->{'range'}->[0] . "," .
                $tcol->{'validate'}->{'range'}->[1] . "]);\n";
        }
    }
    return $vstr;
}



sub doStaticValues
{
    my $argv = $_[0];
    my ($table, $values, $skipempty, $hide, $class);
    my %hidden;
    if ( ref($argv) eq "HASH"  ) {
        argcvt($argv,
               ['table', 'record'],
               ['skipempty', 'hide', 'class'],
               );
        $table = $$argv{'table'};
        $values = $$argv{'record'};
        $skipempty = $$argv{'skipempty'};
        $hide = $$argv{'hide'};
        $class = $$argv{'class'};
        foreach my $h ( @$hide ) {
            $hidden{$h} = 1;
        }
    } else {
        $table = shift;
        $values = shift;
    }

#    print Utility::ObjDump($values);
    my $result = start_table($class ? {-class=>$class} : {});
    
    foreach my $tcol ( @{$table->{'columns'}} ) {
        if ( exists $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            next;
        }
        if ( exists $tcol->{'secure'} && $tcol->{'secure'} eq 'admin' && !Login::isAdmin() ) {
            next;
        }
        if ( exists $tcol->{'secure'} && $tcol->{'secure'} eq 'seesalary' && !Login::canSeeSalary() ) {
            next;
        }
        if ( $skipempty && !$values->{$tcol->{'column'}} ) {
            next;
        }
        if ( $hidden{$tcol->{'column'}} ) {
            next;
        }

        ## If this is part of a variant group, check to see if it is one
        ## of the selected variants.  Also, if it is the variant switch value,
        ## display it always.

        if ( exists $$tcol{'group'} && !exists $$tcol{'switch'} ) {
            my $display = 0;
            my $group = $$table{'groups'}{$$tcol{'group'}};
            my $switchvalue = $values->{$group->{'switch'}};
            foreach my $case ( @{$$group{'cases'}} ) {
                if ( $$case{'column'} ne $$tcol{'column'} ) {
                    next;
                }
                my $hits = scalar grep /^$switchvalue$/, @{$$case{'value'}};
                if ( $hits ) {
                    $display = 1;
                }
            }
            if ( !$display ) {
                next;
            }
        }

        $result .= start_Tr() .
            td({-align=>"right"},b("$tcol->{'heading'}: ")) . start_td();
      SW:{
          $tcol->{'type'} eq "enum" and do {
              $result .= $values->{$tcol->{'column'}} . "\n";
              last SW;
          };
          $tcol->{'type'} eq "set" and do {
              $result .= join(",", @{$values->{$tcol->{'column'}}}) . "\n";
              last SW;
          };
          $tcol->{'type'} eq "email" and do {
              if ( $values->{$tcol->{'column'}} ) {
                  $result .= emailLink($values->{$tcol->{'column'}}) . "\n";
              }
              last SW;
          };
          $tcol->{'type'} eq "url" and do {
              if ( $values->{$tcol->{'column'}} ) {
                  $result .= a({-href=>"$values->{$tcol->{'column'}}", -target=>"_blank"}, $values->{$tcol->{'column'}}) . "\n";
              }
              last SW;
          };

          $tcol->{'type'} eq "text" and do {
              if ( $values->{$tcol->{'column'}} ) {
                  $result .= $values->{$tcol->{'column'}} . "\n";
              }
              last SW;
          };
          $tcol->{'type'} eq "fk" and do {
              if ( $values->{$tcol->{'column'}} ) {
                  my $fktable = $tcol->{'values'}{'table'};
                  if ( $fktable->{'display'} ) {
                      $result .= &{$fktable->{'display'}}($values->{$tcol->{'column'}});
                  } else {
                      my $str = getValueMatch({
                          -table=>$tcol->{'values'}{'table'},
                          -column=>$tcol->{'values'}{'pk'},
                          -equals=>$values->{$tcol->{'column'}},
                          -return=>$tcol->{'values'}{'label'},
                      }) . "\n";
                      $result .= a({-href=>"manage.cgi" .
                                        "?table=$tcol->{'values'}{'table'}{'table'};id=$values->{$tcol->{'column'}};op=display"},
                                   $str);
                  }
              } else {
                  $result .= "null" . "\n";
              }
              last SW;
          };
          $result .= "$values->{$tcol->{'column'}}" . "\n";
      };
        $result .= end_td() . end_Tr() . "\n";
	}

    # Now pick up and N-N rels

    foreach my $tcol ( @{$table->{'rels'}} ) {
        if ( $tcol->{'type'} && $tcol->{'type'} eq "pk" ) {
            next;
        }
        if ( exists $tcol->{'secure'} && $tcol->{'secure'} eq 'admin' && !Login::isAdmin() ) {
            next;
        }
        if ( exists $tcol->{'secure'} && $tcol->{'secure'} eq 'seesalary' && !Login::canSeeSalary() ) {
            next;
        }
        my @nnrecs = getRecordsMatch({-table=>$tcol->{'table'},
                                     -value=>$values->{'id'},
                                     -column=>$tcol->{'column'}[0],
                                  -dojoin=>1});
 #       print Utility::ObjDump(\@nnrecs);
        $result .= start_Tr() .
            td({-align=>"right", -valign=>"top"},b("$tcol->{'heading'}: ")) . start_td() . "\n";

        if ( scalar(@nnrecs) > 0 ) {

            ## construct the name of the field in the returned
            ## record.  Start with the N-N rel description ($tcol)
            ## and pick up the table name for the association table
            ## and the column that our table joins with.  Then from the
            ## association table metadata, pick up the name of the
            ## column in the joined table on the other side of
            ## the association table ($joinlabel).
            ##
            ##                 $tcol->{'table'}
            ## mytable<--middle.leftkey,middle.rightkey-->jointable.joinlabel
            ## 
            my $middletcol = findColumn({-table=>$tcol->{'table'},
                                         -column=>$tcol->{'column'}[1]});
            my $jointable = $middletcol->{'values'}->{'table'};
            my $joinlabel = $middletcol->{'values'}->{'label'};
            my $field = $tcol->{'column'}[1] . "." . $joinlabel;

            my $sep = "";
            foreach my $nnrec ( @nnrecs ) {
                $result .= $sep . $nnrec->{$field};
                $sep = br . "\n";
            }
        }

        $result .= end_td() . end_Tr() . "\n";
    }

    $result .= end_table() . "\n";

    return $result;
}

##
## doAccessDenied
##
## HTML header has already been sent.  Display an access denied page
##

sub doAccessDenied
{
    print doHeading({-title=>"Access Denied"});
    print p("Access to this candidate is limited to the hiring managers");
    print Footer({-url=>self_url()});

    print end_html;
}


sub fullURL
{
    my $script = shift;
    my $host;
    if ( $::ENV{'HTTP_HOST'} ) {
        $host = $::ENV{'HTTP_HOST'};
    } else {
        $host = getValueMatch({
            -table=>\%::ParamTable,
            -column=>"name",
            -equals=>"hostname",
            -return=>"value",
        });
        if ( !$host ) {
            $host = `hostname`;
        }
    }
    return "http://$host" . Utility::rootURL() . $script;
}


##
## Login/out Group
##
##
## doMustLogin - prompt for a login name
##
##   arg 1 ... link of where to go next.
##

sub doMustLogin
{
    if ( !Login::isLoggedIn() ) {
        ConnectToDatabase();
        my $link = shift;
        if ( !defined $link ) {
            $link = self_url();
        }
        print header;
        print Layout::doLoginForm({
            -link=>$link,
            -heading=>"You must log in before you can perform this operation.",
        });
        
        print end_html;
        exit(0);
    }
}

sub doLoginForm
{
    my $menuFormat = Param::getValueByName("menu-login-form");
    my $args = $_[0];
#    $args->{'message'} = Dumper($menuFormat);
    if ( $menuFormat && $menuFormat->{'value'} ) { 
        return doMenuFormatLoginForm($args);
    } else {
        return doSimpleFormatLoginForm($args);
    }
}

##
## Simple log in form - username (or email) and password
##

sub doSimpleFormatLoginForm
{
    my $argv = shift;
    argcvt($argv, ['link'], ['heading', 'message']);

    my $heading = $$argv{'heading'} ? $$argv{'heading'} : "Please Log In";
    my $link = $$argv{'link'};

    my $result = "";

    $result .= doHeading({
        -title=>$heading,
    });

    my $message = $$argv{'message'};
    if ( $message ) {
        print p($message);
    }

    $result .= Layout::startForm({
        -action => "loginout.cgi",
        -name => "loginform",
    }). "\n";
    param("op", "loginfinish");
    $result .= hidden({-name => "op", -default => "loginfinish"}) . "\n";
    $result .= hidden({-name => "link", -default => "$link"}) . "\n";

    $result .= start_table({-border=>"0"}) . "\n";

    $result .= Tr(
        td({-align=>"right"}, "Login: ",br,"(name or email address)"),
        td(textfield({-name => "login_name",},
           ))) . "\n";
    $result .= Tr(
             td({-align=>"right", -id=>"passleft"}, "Password: "),
             td(password_field({-name=>"password", -id=>"passright"})),
             ) . "\n";

    $result .= Tr(
        td('&nbsp;'),
        td(a({-href=>"user.cgi?op=forgot"},'Forgot password?')),
    );

    $result .= Tr(
             td("&nbsp;"),
             td(submit({-name => "submit", -value => "login" })),
             ) . "\n";
    $result .= end_table . "\n";

    $result .= Layout::endForm . "\n";

    $result .= end_table;
    return $result;
}

sub doForgotPasswordForm
{
    my $argv = shift;
    argcvt($argv, [], ['heading', 'message']);

    my $heading = $$argv{'heading'} ? $$argv{'heading'} : "Forgot password";

    my $result = "";
    $result .= doHeading({
        -title=>$heading,
                         });
    my $message = $$argv{'message'};
    if ( $message ) {
        print p($message);
    }

    $result .= Layout::startForm({
        -action => "user.cgi",
        -name => "userform",
    }). "\n";
    param("op", "sendpwemail");
    $result .= hidden({-name => "op", -default => "sendpwemail"}) . "\n";

    $result .= start_table({-border=>"0"}) . "\n";

    $result .= Tr(
        td({-align=>"right"}, "Login name: ",br,"(name or email address)"),
        td(textfield({-name => "login_name",},
           ))) . "\n";
    $result .= Tr(
             td("&nbsp;"),
             td(submit({-name => "submit", -value => "Send Password Email" })),
             ) . "\n";
    $result .= end_table . "\n";

    $result .= Layout::endForm . "\n";

    $result .= end_table;
    return $result;

}

sub doMenuFormatLoginForm
{

    my $argv = shift;
    argcvt($argv, ['link'], ['heading','message']);

    my $heading = $$argv{'heading'} ? $$argv{'heading'} : "Please Log In";
    my $link = $$argv{'link'};

    my $result = "";


    my $script = <<END;
    // passmap holds the indices of the user ids who have passwords
    var passmap = new Array;
END

    my @users = getAllRecords({
        -table=>\%::UserTable,
    });
    @users = sort {$$a{'id'} <=> $$b{'id'}} @users;

    $script .= "passmap = [ ";
    my $sep = "";
    foreach my $user ( @users ) {
        if ( $user->{'password'} ) {
            $script .= "$sep$user->{'id'}";
            $sep = ",";
        }
    }
    $script .= "];\n";

    $script .= <<END;
function checkpass(user, idleft, idright)
{
  var haspass = 0;
  for ( i=0 ; i<passmap.length ; i++ ) {
    if ( passmap[i] == user.value ) {
      haspass = 1;
      break;
    }
  }
  var leftcell = document.getElementById(idleft);
  var rightcell = document.getElementById(idright);
  if ( haspass ) {
      leftcell.style.visibility = "visible";
      rightcell.style.visibility = "visible";
  } else {
      leftcell.style.visibility = "hidden";
      rightcell.style.visibility = "hidden";
  }
}
END


    $result .= doHeading({
        -title=>$heading,
        -script=>$script,
    });

    $result .= Layout::startForm({
        -action => "loginout.cgi",
        -name => "loginform",
    }). "\n";
    param("op", "loginfinish");
    $result .= hidden({-name => "op", -default => "loginfinish"}) . "\n";
    $result .= hidden({-name => "link", -default => "$link"}) . "\n";

    $result .= start_table({-border=>"0"}) . "\n";
    $result .= Tr(
             td({-align=>"right"}, "Login: "),
             td(PulldownMenu({
                 -table => \%::UserTable,
                 -column => "name",
                 -name => "login_id",
                 -onchange=>"checkpass(this, 'passleft','passright');",
             })),
             ) . "\n";
    $result .= Tr(
             td({-align=>"right", -id=>"passleft"}, "Password: "),
             td(password_field({-name=>"password", -id=>"passright"})),
             ) . "\n";

    $result .= Tr(
        td('&nbsp;'),
        td(a({-href=>"."},'Forgot password?')),
    );

    $result .= Tr(
             td("&nbsp;"),
             td(submit({-name => "submit", -value => "login" })),
             ) . "\n";
    $result .= end_table . "\n";

    $result .= Layout::endForm . "\n";
    $result .= start_script . "\n";
    $result .= "checkpass(document.loginform.login_id,'passleft','passright');\n";
    $result .= end_script . "\n";
    return $result;
}

##
## doHeading - do the start_html and optionally the h1 at the top of
##             each page.
##
## Required parameters:
##    None.
##
## Optional parameters:
##    title ....... string to use as the page title, including the h1
##    head ........ other <HEAD> tags as described in the start_html
##                  description
##    onload ...... an optional onload script
##    noheading ... if defined, no h1 construct is created
##    script ...... either a javascript or a hash as described in the
##                  start_html description
##    nostyle ..... if define and non-zero, skips the stylesheet
##    noscript .... don't include the javascript validators
##    noline ...... don't print the horizontal rule in the heading
##

sub doHeading
{
    my $argv = shift;
    argcvt($argv, [], ['title',      # used as the <h1> and the <title>
                       'script',     # optional additional JavaScript
                       'head',       # additional <head> elements
                       'onload',     # optional onload tag value
                       'noheading',  # if defined & true, skip <h1>
                       'nostyle',    # if defined & true, skip default CSS
                       'noscript',   # if defined and true, skip default JS
                       'noline',     # if defined and trum skip <hr>
                       ]);
    my $result = "";

    my %args = (-title=>$$argv{'title'},
                -head=>$$argv{'head'},
                -onload=>$$argv{'onload'},
                );
    unless ( $$argv{'nostyle'} ) {
        $args{'-style'} = {-src=>"style.css"};
    }
        

    ## build up the list of javascript pieces.  Always load the
    ## validators unless '-noscript'.  If there is a -script argument,
    ## append it.
    ## The argument could be a HASH or just a scalar.

    my @scripts = ();
    unless ( $$argv{'-noscript'} ) {
        push @scripts, { -language => 'JavaScript1.2', -src => "javascript/validators.js" };
    }

    if ( exists $$argv{'script'} ) {
        if ( ref($$argv{'script'}) eq "HASH" ) {
            push @scripts, $$argv{'script'};
        } elsif ( ref($$argv{'script'}) eq "ARRAY" ) {
            push @scripts,@{$$argv{'script'}};
        } else {
            push @scripts, {-language=>'JavaScript', -code=>$$argv{'script'}};
        }
    }
    $args{'script'} = \@scripts;
    $result .= start_html(\%args);
    
    if ( !exists $$argv{'noheading'} ) {
        $result .= table({-width=>"100%", -class=>"heading"},
                         Tr(
                            td(h1($$argv{'title'}), "\n"), "\n",
                            td({-align=>"right"}, a({-href=>Utility::rootURL()}, "Home"), br, "\n",
                               $Layout::headstr),
                            ), "\n",
                         ) . "\n";
        if ( !exists $$argv{'noline'} ) {
            $result .= hr() . "\n";
        }
    }
    return $result;
}

sub setHeadingRight
{
    $Layout::headstr = shift;
}

sub emailLink
{
    my $value = shift;
    my @list = split /[,;]/,$value;

    my $result = "";
    my $sep = "";
    foreach my $value ( @list ) {
        $result .= $sep . a({-href=>"mailto:$value"},"$value");
        $sep = ", ";
    }
    return $result;
}

1;
