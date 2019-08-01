# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

package Database;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw(&ConnectToDatabase 
             &GetDBVersion 
             &SetDBVersion
             &ColumnsList 
             &SQLQuote 
             &SQLSend 
             &SQLMoreData 
             &SQLAffectedRows 
             &SQLInsertId 
             &SQLFetchData 
             &SQLFetchOneColumn 
             &GetTableNames 
             &dumpTableSchema
             &dumpQueries
             &getAllRecords
             &getPKsMatch
             &getRecordsMatch
             &getRecordsWhere
             &formJoinQuery
             &getRecordById
             &getValueMatch
             &makeMap
             &getRecordMap
             &writeComplexRecord
             &writeSimpleRecord
             &updateSimpleRecord
             &deleteSimpleRecord
             &readComplexRecord
             &deleteComplexRecord
             &EnumsList
             &SetList);

@EXPORT_OK = qw();              # Symbols to export on request

#use Mysql;
use DBI;
use CGI qw(:standard *p *Tr *td *table *li *ul);
use Argcvt;
use Utility;

my $fulltrace = 0;

sub setFullTrace
{
    $fulltrace = shift;
}


require "DATABASE.pl";

my $dbh;
my $sth;


sub ConnectToDatabase
{
    my $silent = shift;

    if (!defined $dbh) {
        $dbh = DBI->connect($::DB_SOURCE, $::DB_USER, $::DB_PASS);
        if ( !$dbh ) {
            my $err = $DBI::errstr;
            Utility::redError("Connect to database failed: $err") if (!$silent);
            return 0;
        } else {
            return 1;
        }
    }
    return 1;
}

sub SetDBVersion
{
    my ($version) = (@_);
    SQLSend("UPDATE param SET value=" . SQLQuote($version) . " WHERE name='version'");
}

sub GetDBVersion
{
    SQLSend("SELECT value FROM param WHERE name = 'version'");
    my $r = SQLFetchOneColumn();
    if (!defined $r || $r eq "") {
        return undef;
    }
    return $r;
}

##################################################################
##
## ColumnList - return an array containing given table's column names
##
##
#
# Required parameters:
#    -table => name of the DB table (text name)
# Optional parameters:
#    none.

sub ColumnsList($)
{
    my $argv = shift;
    argcvt($argv, ['table'], []);
    my $table = $$argv{'table'};;
    SQLSend("SHOW COLUMNS FROM $table");
    my (@fields, @cols);
    while ( @fields = SQLFetchData() ) {
        push @cols, $fields[0];
    }
    return @cols;
}



sub SQLQuote(@)
{
    my ($str) = (@_);
    if ( !defined $str ) {
        Utility::redError("SQLQuote an undefined string");
          return "''";
      }
    $str =~ s/([\\\'])/\\$1/g;
    $str =~ s/\0/\\0/g;
    return "'$str'";
}


## first arg is query string
## second arg is array of params

sub SQLSend(@)
{
    my ($str,@binds) = (@_);
    

    ## If full query tracing is turned on, show where the query comes from

    if ( $fulltrace ) {
        my $trace = "";
        my $sep = "";
        for ( my $i=6; $i>0 ; $i-- ) {
            my ($pack, $file, $line, $subname, $hasargs, $wantarray) = caller($i);
            if ( defined $subname ) {
                $trace .=  "$sep" . $subname . "() called from $file:$line";
                $sep = "\n";
            }
        }
        addQueryComment($trace) if $trace;
    }        
    addQuery($str);

    if ( !defined $dbh ) {
        Utility::redError("SQLSend: DB object undefined. \"$str\"");
    } else {
        unless ( $::SQL_NOWRITE && ( $str =~ /^update/i || $str =~ /^insert/i ) ) {
            $sth = $dbh->prepare($str);
            if ( $dbh->err ) {
                Utility::redError( "$str: " . $dbh->errstr );
            } else {
                $sth->execute(@binds);
                if ( $dbh->err ) {
                    Utility::redError( "$str: " . $dbh->errstr );
                }
            }
        }
    }
}

sub SQLMoreData()
{
    if (@::fetchahead) {
        return 1;
    }
    if (@::fetchahead = $sth->fetchrow_array()) {
        return 1;
    }
    return 0;
}

sub SQLAffectedRows()
{
    return $sth->rows();
}

sub SQLInsertId()
{
    return $sth->insertid();
}

sub SQLFetchData()
{
    if (@::fetchahead) {
        my @result = @::fetchahead;
        undef @::fetchahead;
        return @result;
    }
    if ( !defined $sth ) {
        Utility::redError("SQLFetchData: query object is undefined");
          return undef;
      } else {
          return $sth->fetchrow();
      }
}


sub SQLFetchOneColumn()
{
    my @row = SQLFetchData();
    return $row[0];
}

sub GetTableNames()
{
    my @tables = $dbh->tables();
    for ( my $i=0 ; $i<scalar(@tables) ; $i++ ) {
        $tables[$i] =~ s/[^\w.]//g;
        $tables[$i] =~ s/\w*\.//;
    }
        
    return @tables;
}

#
#  dumpTableSchema - display the DB schema in HTML
#
# Required parameters:
#    -table => name of the DB table (text name)
# Optional parameters:
#    none.

sub dumpTableSchema($)
{
    my $argv = shift;
    argcvt($argv, ['table'], []);
    my $table = $$argv{'table'};

    my @fields;
    my $first = 0;

    print start_table({-border=>"1", -cellspacing=>"0", -cellpadding=>"4"}),
    Tr(
       td(b("Field")),
       td(b("Type")),
       td(b("Null")),
       td(b("Key")),
#       td(b("Extra")),
       td(b("Default")),
       td(b("Privileges")),
       );
    SQLSend("SHOW COLUMNS FROM $table");
    while ( @fields = SQLFetchData() ) {
        while ( scalar(@fields) < 6 ) {
            unshift @fields, "";
        }
        foreach my $i ( @fields ) {
            if ( $first ) {
                print td(b($i)), "\n";
            } else {
                if ( $i ) {
                    print td($i), "\n";
                } else {
                    print td("\&nbsp;");
                }
            }
        }
        print end_Tr;
        $first = 0;
    }
    print end_table;
}


##################################################################
##
## query display code
##

sub addQuery(@)
{
    my $query = shift;
    if ( $query =~ /^#/ ) {  # for backward compatibility
         $query =~ s/^# *//;
         Database::addQueryComment($query);
     } else {
         push @::QUERIES, { 'query'=>"$query", 'type'=>'sql' };
     }
}

sub addQueryComment(@)
{
    my $query = shift;
    push @::QUERIES, { 'query'=>"$query", 'type'=>'comment' };
}

sub allQueries()
{
    my $re = shift;
    my $str = "";
    foreach my $q ( @::QUERIES ) {
        if ( !defined $re || ($q->{'type'} eq 'sql' && $q->{'query'} =~ /$re/i )) {
            $str .= $q . "\n";
        }
    }
    return $str;
}

sub clearQueries()
{
    @::QUERIES = ();
}

sub dumpQueries()
{
    my $str = "";
    if ( scalar @::QUERIES > 0 ) {

        $str = <<'END';
        <script Language="JavaScript"><!--
            function showsql()
{
    var w = window.open("", "sql", "resizable,status,width=625,height=400,scrollbars=yes");
    var d = w.document;
END
        foreach my $q ( @::QUERIES ) {
            my $text = $q->{'query'};
            if ( $q->{'type'} eq 'sql' ) {
                $text =~ s/\'/\\\'/g;
                $text =~ s/[\n\r]/ /g;
                $text =~ s/  */ /g;
                $text = escapeHTML($text);
            } else {
                $text =~ s/\'/\\\'/g;
                $text =~ s/^/# /;
                $text =~ s/[\n\r]/<br># /g;
            }                
            $str .= "d.write('<P>$text</P>');";
        }

    $str .= <<'END';
    d.close();
    return false;
}
//--></script>
    <p align="right"><form><button onClick="return showsql()">SQL</button></form></p>
END
}
return $str;
}

##
## getAllRecords - return an array of hashes of all records in a given table
##
## Required parameters:
##    -table => name of the DB table (the hash)
## Optional parameters:
##    none.

sub getAllRecords
{
    my $argv = shift;
    
    argcvt($argv, ['table'], []);
    my $table = $$argv{'table'};

    my $cols = "";
    my $sep = "";
    foreach my $tcol ( @{$table->{'columns'}} ) {
        $cols .= "$sep$tcol->{'column'}";
        $sep = ",";
        if ( $tcol->{'type'} eq "datetime" ) {
            $cols .= $sep . "UNIX_TIMESTAMP($tcol->{'column'})";
        }
    }
    my $query = "SELECT $cols from $table->{'table'}";
    if ( exists $table->{'order'} ) {
        $query .= " ORDER BY $table->{'order'}";
    }
    SQLSend($query);
    my @vals;
    my @results;
    my $record;
    while ( @vals = SQLFetchData() ) {
        $record = {};
        foreach my $tcol ( @{$table->{'columns'}} ) {
            $record->{$tcol->{'column'}} = shift @vals;
            if ( $tcol->{'type'} eq "datetime" ) {
                $record->{"u_$tcol->{'column'}"} = shift @vals;
            }
        }
        push @results, $record;
    }
    return @results;
}

##
## getPKsMatch - return an array of PKs from a table whose rows match a match condition
##
## Required parameters:
##    table .... hash of the table metadata
##    column ... column to match
##    value .... value in that column to match
## Optional parameters:
##    none
##

sub getPKsMatch($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'column', 'value'], []);
    my $table = $$argv{'table'};

    my $query = "SELECT id FROM $table->{'table'} WHERE $$argv{'column'} = " . SQLQuote($$argv{'value'});
    if ( exists $table->{'order'} ) {
        $query .= " ORDER BY $table->{'order'}";
    }

    SQLSend($query);
    my $result;
    my @results;
    while ( $result = SQLFetchOneColumn() ) {
        push @results, $result;
    }
    return @results;
}

sub getPKsWhere($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'where'], []);
    my $table = $$argv{'table'};

    my $query = "SELECT id FROM $table->{'table'} WHERE $$argv{'where'}";
    if ( exists $table->{'order'} ) {
        $query .= " ORDER BY $table->{'order'}";
    }

    SQLSend($query);
    my $result;
    my @results;
    while ( $result = SQLFetchOneColumn() ) {
        push @results, $result;
    }
    return @results;
}

sub getAllPKs
{
    my $argv = shift;
    argcvt($argv, ['table'], []);
    my $table = $$argv{'table'};

    my $query = "SELECT id FROM $table->{'table'}";
    SQLSend($query);
    my $result;
    my @results;
    while ( $result = SQLFetchOneColumn() ) {
        push @results, $result;
    }
    return @results;
}

##
## getRecordsMatch - return an array of hashes from a table whose rows
## match a match condition
##
## Required parameters:
##    table .... hash of the table metadata
##    column ... column to match
##    value .... value in that column to match
##
## Optional parameters:
##    rel ...... relationship to check between column and value, default '='
##    dojoin ... passed along to getRecordsWhere
##    nojoin ... passed along to getRecordsWhere
##
##    Note: column and value can be arrays, forming a conjunction
##

sub getRecordsMatch($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'column', 'value'], ['rel', 'dojoin', 'nojoin']);

    my $where = "";
    if ( ref($$argv{'column'}) eq "ARRAY" ) {
        my $sep = "";
        for ( my $i=0 ; $i<scalar @{$$argv{'column'}} ; $i++ ) {
            $where .= $sep . $$argv{'column'}->[$i] .
                ($$argv{'rel'} ? " $$argv{'rel'}->[$i] " : ' = ' ) .
                SQLQuote($$argv{'value'}->[$i]);
            $sep = " AND ";
        }
    } else {
        $where = "$$argv{'column'}" .
            ($$argv{'rel'} ? " $$argv{'rel'} " : ' = ' ) .
            SQLQuote($$argv{'value'});
    }
    my %args = (
                -table => $$argv{'table'},
                -where=>$where,
                );
    exists $$argv{'dojoin'} and $args{'dojoin'} = $$argv{'dojoin'};
    exists $$argv{'nojoin'} and $args{'nojoin'} = $$argv{'nojoin'};
    return getRecordsWhere(\%args);
}

##
## getRecordsWhere - get DB records based on a WHERE clause
##
## Required named parameters:
##   table ..... ref to the table hash
##   where ..... text of the WHERE clause (without the WHERE)
##
## Optional named parameters:
##   dojoin .... define to any value to join one level deep through *:1 rels
##   nojoin .... name of a column to not join on.
##


sub getRecordsWhere($)
{
    my $argv = shift;
    argcvt($argv, ['table'], ['dojoin', 'nojoin', 'where']);
    my $table = $$argv{'table'};
    my $where = $$argv{'where'};
    my $dojoin = exists $$argv{'dojoin'} && $$argv{'dojoin'}>0;

    my $query;
    my $hashes;
    if ( $dojoin ) {
        my ($selects, $tables, $joins);
        ($selects, $tables, $joins, $hashes) = formJoinQuery({-table=>$table,
                                                              -follow=>$$argv{'dojoin'},
                                                              -nojoin=>$$argv{'nojoin'}});
        $query = "SELECT $selects FROM $tables $joins";
    } else {
        my $cols = "";
        my $sep = "";
        foreach my $tcol ( @{$table->{'columns'}} ) {
            $cols .= "$sep$tcol->{'column'}";
            $sep = ",";
            if ( $tcol->{'type'} eq "datetime" ) {
                $cols .= $sep . "UNIX_TIMESTAMP($tcol->{'column'})";
            }
        }
        $query = "SELECT $cols from $table->{'table'}";
    }
    if ( $where ) {
        $query .= " WHERE $where";
    }
    
    if ( exists $table->{'order'} ) {
        $query .= " ORDER BY $table->{table}.$table->{'order'}";
    }
    SQLSend($query);
    my @vals;
    my @results;
    my $record;
    while ( @vals = SQLFetchData() ) {
        $record = {};
        if ( $dojoin ) {
            foreach my $col ( @$hashes ) {
                $record->{$col} = shift @vals;
            }
        } else {
            foreach my $tcol ( @{$table->{'columns'}} ) {
                $record->{$tcol->{'column'}} = shift @vals;
                if ( $tcol->{'type'} eq "datetime" ) {
                    $record->{"u_$tcol->{'column'}"} = shift @vals;
                }
            }
        }
        push @results, $record;
    }

    ##
    ## If there are any N-N rels, fetch the data as 1-N rels
    ##

    if ( $dojoin ) {
        foreach my $rel ( @{$table->{'rels'}} ) {
            foreach my $rec ( @results ) { 
              SW: {
                  $rel->{'type'} eq "1-N" and do {
                      my @recs = getRecordsMatch({
                          -table=>$rel->{'table'},
                          -column=>$rel->{'column'},
                          -value=>$rec->{'id'},
                          -dojoin=>0,
                      });
                      $rec->{$rel->{'hashkey'}} = \@recs;
                      last SW;
                  };
                  $rel->{'type'} eq "N-N" and do {
                      my @recs = getRecordsMatch({
                          -table=>$rel->{'table'},
                          -column=>$rel->{'column'}[0],
                          -nojoin=>"candidate_id",
                          -value=>$rec->{'id'},
                          -dojoin=>1,
                      });
                      $rec->{$rel->{'hashkey'}} = \@recs;
                      last SW;
                  };
              };
            }
        }
    }
    if ( wantarray() ) {
        return @results;
    } else {
        return [ @results ];
    }
}

##
## formJoinQuery - for a query to read a record, joining with the columns from
##                 other tables referenced via foreign keys
##
## Required named parameters:
##    table ... reference to the primary table metadata hash
##
## Optional parameters:
##    follow ... 1 to follow all foreign keys, 0 to not, default 1
##    alias .... the table alias
##    nojoin ... name of a single column to not join on (should be array ref)
##
## Returns:
##    [0] - selects list as a comma separated string
##    [1] - tables list as a comma separated string
##    [2] - join list for the joins as a string
##    [3] - array of hash variables parallel to the selects
##
## Usage:
##    my ($selects, $tables, $joins, $hashes) = formJoinQuery({-table=>$table});
##
## The select statement the caller could form would be
##    SELECT [0] FROM [1] [2]
## The caller can add additional WHERE clauses like this:
##    SELECT [0] FROM [1] [2] WHERE where-clauses
##

sub formJoinQuery($);

sub formJoinQuery($)
{
    my $argv = shift;

    argcvt($argv, ["table"], ['follow', 'tables', 'nojoin', 'alias']);
    my $table = $$argv{'table'};
    my $follow = exists $$argv{'follow'} ? $$argv{'follow'} : 0;

    my $selects = "";
    my $selectsep = "";
    my @hashes = ();

    my $joins;
    my @joinkeys = ();
    my $tablehash = { $table->{'table'} => 1 };
    my @nestedjoins = ();
    my %aliasindex;

    my $tablename;
    if ( $$argv{'alias'} ) {
        $tablename = $$argv{'alias'};
    } else {
        $tablename = $table->{'table'};
    }

    foreach my $tcol ( @{$table->{'columns'}} ) {
        $selects .= "$selectsep$tablename.$tcol->{'column'}";
        $selectsep = ", ";
        push @hashes, $tcol->{'column'};

        if ( $tcol->{'type'} eq "datetime" ) {
            $selects .= "$selectsep" . "UNIX_TIMESTAMP($tablename.$tcol->{'column'})";
            $selectsep = ", ";
            push @hashes, "u_$tcol->{'column'}";
        }

#        $tcol->{'type'} eq "fk" && print p("Col=",$tcol->{'column'}, br,
#                "Type=", $tcol->{'type'}, br,
#                "follow=>", $follow,br,
#                "fk table=",$tcol->{'values'}->{'table'}->{'table'},br,
#                "tablehash=",$tablehash->{$tcol->{'values'}->{'table'}->{'table'}},
#                $$argv{'nojoin'}, );
        if ( $tcol->{'type'} eq "fk" && $follow > 0 &&
             !exists $tablehash->{$tcol->{'values'}->{'table'}->{'table'}} &&
             !(exists $$argv{'nojoin'} && defined $$argv{'nojoin'} && $$argv{'nojoin'} eq $tcol->{'column'}) ) {

            my $fk_table =  $tcol->{'values'}->{'table'}->{'table'};

#            print p("Col=",$tcol->{'column'}, br,
#                    "aliasindex=",$aliasindex{$fk_table});

            ## XXX If there is a duplicate table name at a lower level, this fails.  E.g.
            ##  candidate
            ##     user owner
            ##     opening
            ##        user hiring-manager
            ##
            my $alias;
            if ( !exists $aliasindex{$fk_table} ) {
                $aliasindex{$fk_table} = 1;
                $alias = $fk_table;
            } else {
                $alias = sprintf("%s_%02d", $fk_table,$aliasindex{$fk_table});
                $aliasindex{$fk_table}++;
            }



            my ($nselects, $ntables, $njoins, $nhashes) = formJoinQuery({-table=>$tcol->{'values'}->{'table'},
                                                                         -follow=>$follow-1,
                                                                         -tables=>$tablehash,
                                                                         -alias=>$alias,
                                                                     });
            $selects .= ", $nselects";
            $joins .= $njoins if ( defined $njoins);

            $joins = " LEFT JOIN $fk_table" . ($fk_table eq $alias ? "" : " $alias") . " ON " .
                "$table->{'table'}.$tcol->{'column'} = $alias.$tcol->{'values'}->{'pk'}" .
                " " . (defined $joins ? $joins : "");

 #           print p("Col=",$tcol->{'column'}, br,
 #                   "joins=",$joins);
            ## There may be several needed LEFT JOINs for any particular foreign table.  Collect them
            ## all in a hash of arrays keyed by the foreign table name.  Save in joinkeys the order
            ## that these were encountered.

            foreach my $h ( @$nhashes ) {
                push @hashes, "$tcol->{'column'}.$h";
            }

        }
    }

#   print p("SELECT $selects FROM $table->{'table'} $joins", br, "HASHES: ",join(", ", @hashes));
    return ($selects, $table->{'table'}, $joins, \@hashes);
}

##
## getRecordById - return a row of a table matching a particular PK
##
## Required parameters:
##   table ... hash of the table meta data
##   id ...... value of the PK
## Optional parameters:
##   none.

sub getRecordById($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'id'], []);
    my @records = getRecordsMatch({-table=>$$argv{'table'},
                                   -column=>"id",
                                   -value=>$$argv{'id'}});
    my $ref = $records[0];
    if ( !defined $ref ) {
#        Utility::redError(
#        "getRecordById didn't return any values ($$argv{'table'}{'table'},$$argv{'id'})");
#          print Utility::ObjDump($argv);
          return undef;
      }
    if ( wantarray() ) {
        return %$ref;
    } elsif ( defined wantarray() ) {
        return $ref;
    } else {
        return;
    }
}


## getValueMatch - return a single column value from a row matching the given criterion
##
## Required parameters:
##    table .... has of the table meta data
##    return ... column to return
##    equals .... column value to match
## Optional parameters:
##    column .... column to match, defaults to 'id'
##

sub getValueMatch($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'equals', 'return'], ['column']);
    my $table = $$argv{'table'};
    my $column = exists $$argv{'column'} ? $$argv{'column'} : 'id';

    my $query = "select $$argv{'return'} FROM $table->{'table'} WHERE $column = " . SQLQuote($$argv{'equals'});
    SQLSend($query);
    return SQLFetchOneColumn();
}

##
## getRecordMap - create a hash that maps one column (domain) of a DB into the full record
##
## Required parameters
##     table ... ref to the table hash
## Optional Parameters:
##     column .. domain column (default "id")
##

sub getRecordMap($)
{
    my $argv = shift;
    argcvt($argv, ['table'], ['column']);
    my $domain = exists $$argv{'column'} ? $$argv{'column'} : "id";

    my @records = getAllRecords({-table=>$$argv{'table'}});
    my %map;

    foreach my $rec ( @records ) {
        $map{$rec->{$domain}} = $rec;
    }
    return %map;
}


##
## makeMap - create a hash that maps one column (domain) of a DB
##           into another (range)
##

sub makeMap($$$)
{
    my ($table, $domain, $range) = (@_);

    my @records = getAllRecords({-table=>$table});
    my %map;

    foreach my $rec ( @records ) {
        $map{$rec->{$domain}} = $rec->{$range};
    }
    return %map;
}



##
## writeComplexRecord - write a hash-linked record to the DB
##
## Required parameters:
##    table .... ref to Table hash
##    record ... ref to has record to write
##
## Walk the in-memory hash structure.  Use the @rels list in the
## metadata to determine which paths lead to contained records. 
## Fill the contained records with the correct FK
## value of the recently written record's PK
##

sub writeComplexRecord($);

                       sub writeComplexRecord($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'record'], []);
    my $table = $$argv{'table'};
    my $rec = $$argv{'record'};

    my $newid = writeSimpleRecord({-table=>$table, -record=>$rec});
    foreach my $con ( @{$table->{'rels'}} ) {
      SWITCH: {
          $con->{'type'} eq "1-N" and do {
              foreach my $child ( @{$rec->{$con->{'hashkey'}}} ) {
                  $child->{$con->{'column'}} = $newid;
#                  print Utility::ObjDump($child);
                  writeComplexRecord({
                      -table=>$con->{'table'},
                      -record=>$child,
                  });
              }
              last SWITCH;
          };
          Utility::redError("$table->{'table'} metadata has invalid rel type $con->{'type'}");
      };
    }
    return $newid;
}

##
## updateSimpleRecord - update a record, don't follow links
##
## Required named parameters:
##  table .... ref to table meta data hash
##  old ...... ref to old record hash
##  new ...... ref to new record has
##
## Optional named parameters
##  donulls ... if true, NULL out columns that are missing in new
##

sub updateSimpleRecord($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'old', 'new'], ['donulls']);
    my $table = $$argv{'table'};
    my $old = $$argv{'old'};
    my $new = $$argv{'new'};
    my $donulls = $$argv{'donulls'};

    my $pkcol;
    my $updates = "";
    my $sep = "";
    my $mods = 0;
    foreach my $tcol ( @{$table->{'columns'}} ) {
        if ( $tcol->{'type'} eq "pk" ) {
            $pkcol = $tcol->{'column'};
            next;
        }
        if ( $tcol->{'column'} eq "modtime" ) {
            $updates .= "$sep$tcol->{'column'} = NOW()";
            $sep = ",";
        } else {
            if ( exists $$old{$tcol->{'column'}} && defined $$old{$tcol->{'column'}} ) {
#                if ( exists $$new{$tcol->{'column'}} && defined $$new{$tcol->{'column'}} ) {
                if ( exists $$new{$tcol->{'column'}} ) {
                    if ( $$old{$tcol->{'column'}} ne $$new{$tcol->{'column'}} ) {
                        ##
                        ## Both the old and new values exist, and they are different.
                        ## Add the new value to the DB UPDATE statement
                        if ( defined $$new{$tcol->{'column'}} ) {
                            $updates .= "$sep$tcol->{'column'} = " . SQLQuote($$new{$tcol->{'column'}});
                        } else {
                            $updates .= "$sep$tcol->{'column'} = NULL";
                        }
                        $sep = ",";
                        $mods++;
                    }  else {
                        ##
                        ## The old value and new values both exist, and they are equal - do nothing
                        ##
                    }

                } else {
                    ##
                    ## The old value exists and is defined.
                    ## The new value does not exist.
                    ## Set the DB column to NULL if the 'donulls' arg is given
                    ##
                    if ( $donulls ) {
                        $updates .= "$sep$tcol->{'column'} = NULL";
                        $sep = ",";
                        $mods++;
                    }
                }
            } else { #no old value
                if ( exists  $$new{$tcol->{'column'}} ) {
                    ##
                    ## No old value
                    ## New value exists
                    ##
                    if ( defined $$new{$tcol->{'column'}} ) {
                        $updates .= "$sep$tcol->{'column'} = " . SQLQuote($$new{$tcol->{'column'}});
                        $sep = ",";
                        $mods++;
                    } else {
                        if ( $donulls ) {
                            $updates .= "$sep$tcol->{'column'} = NULL";
                            $sep = ",";
                            $mods++;
                        }
                    }
                }
            }
        }
    }
    if ( $mods > 0 ) {
        my $query = "UPDATE $table->{'table'} SET $updates WHERE $pkcol = " . SQLQuote($$old{$pkcol});
        SQLSend($query);
    }
    
}


##
## writeSimpleRecord - write a hash-linked record to the DB
##
## Required named parameters:
##    -table .... ref to Table hash
##    -record ... ref to record to write
##
## Optional named parameters:
##    -allownulls ... allow data to be missing from the has structure $rec
##    -creation ..... normally the creation datetime is automatically generated.  This
##                    allows the caller to set it explicitly
##


sub writeSimpleRecord($)
{
    my $argv = shift;

    argcvt($argv, ['table', 'record'], ['allownulls', 'creation']);

    my $allownulls = 0;
    if ( defined $argv && $$argv{'allownulls'} ) {
        $allownulls = 1;
    }

    my $table = $$argv{'table'};
    my $rec = $$argv{'record'};
    
    my $collist = "";
    my $vallist = "";
    my $sep = "";
    my @blobs = ();
    foreach my $tcol ( @{$table->{'columns'}} ) {
        my $column = $tcol->{'column'};
        if ( $tcol->{'type'} eq "pk" ) {
            next;
        }
        if ( $column eq "creation" || $column eq "modtime" ) {
            $collist .= "$sep$column";
            if ( $column eq "creation" && $$argv{'creation'} ) {
                $vallist .= $sep . SQLQuote($$argv{'creation'});
            } else {
                $vallist .= $sep . "NOW()";
            }
            $sep = ",";
        } else {
            if ( exists $rec->{$column} && defined $rec->{$column} ) {
                $collist .= "$sep$column";
                if ( $tcol->{'type'} eq "blob" ) {
                    $vallist .= "$sep" . "?";
                    push @blobs, $rec->{$column};
                } else {
                    $vallist .= "$sep" . SQLQuote($rec->{$column});
                }
                $sep = ",";
            } else {
                if ( !$allownulls && !$tcol->{'nullable'} ){
                    Utility::redError("$table->{'table'} metadata describes column \"$column\" which is missing from the in-memory record");
                  }
            }
        }
    }
    my $query = "INSERT INTO $table->{'table'} ( $collist ) VALUES ( $vallist )";
    SQLSend($query, @blobs);
    if ( defined wantarray() ) { # any context?
        SQLSend("Select LAST_INSERT_ID()");
        return  SQLFetchOneColumn();
    } else {
        return;
    }
}

##
## deleteSimpleRecord - delete a row from a table where al columns match
##
## Required parameters:
##    table ..... ref to the table hash
##    record .... a hash record
##
## entries in the given table that exactly match the record are deleted.
##

sub deleteSimpleRecord($);

sub deleteSimpleRecord($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'record']);
    my $table = $$argv{'table'};
    my $record = $$argv{'record'};

    my $query = "DELETE from $$table{'table'} where";
    my $sep = "";
    foreach my $k ( keys %$record ) {
        $query .= "$sep $k = " . SQLQuote($$record{$k});
        $sep = " AND";
    }
    SQLSend($query);
}

##
## readComplexRecord
##
## Required parameters:
##    table ..... ref to the table hash
##    value .... value to match on that column
## Optional parameters:
##    column .... column to match (default 'id')
##

sub readComplexRecord($);

                      sub readComplexRecord($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'value'], ['column']);
    my $table = $$argv{'table'};
    my $id = $$argv{'value'};
    my $column = exists $$argv{'column'} ? $$argv{'column'} : "id";

    my @recs = getRecordsMatch({-table=>$table,
                                -column=>$column,
                                -value=>$id});
    foreach my $rec ( @recs ) {
        foreach my $con ( @{$table->{'rels'}} ) {
          SWITCH: {
              $con->{'type'} eq "1-N" and do {
                  my @children = readComplexRecord({
                      -table=>$con->{'table'},
                      -column=>$con->{'column'},
                      -value=>$rec->{'id'},
                  });
                  $rec->{$con->{'hashkey'}} = \@children;
                  last SWITCH;
              };
              $con->{'type'} eq "N-N" and do {
                  # skip the back pointer
                  if ( $con->{'column'}[1] ne $rec->{'id'} ) {
                      my @children = readComplexRecord({
                          -table=>$con->{'maptable'},
                          -column=>$con->{'column'}[1],
                          -value=>$rec->{'id'},
                      });
                      print Utility::ObjDump(\@children);
                  }
                  last SWITCH;
              };
              Utility::redError("$table->{'table'} metadata has invalid rel type \"$con->{'type'}\"");
          };
        }
    }
    return @recs;
}

##
## deleteComplexRecord
##

sub deleteComplexRecord($);

                        sub deleteComplexRecord($)
{
    my $argv = shift;
    argcvt($argv, ['table', 'value'], ['column']);
    my $table = $$argv{'table'};
    my $id = $$argv{'value'};
    my $column = exists $$argv{'column'} ? $$argv{'column'} : "id";

    my @recs = getRecordsMatch({-table=>$table,
                                -column=>$column,
                                -value=>$id});
    my $query = "DELETE from $table->{'table'} where $column = " . SQLQuote($id);
    SQLSend($query);
    foreach my $rec ( @recs ) {
        foreach my $con ( @{$table->{'rels'}} ) {
            if ( exists $con->{'containment'} && $con->{'containment'} ) {
              SWITCH: {
                  $con->{'type'} eq "1-N" and do {
                      deleteComplexRecord({
                          -table=>$con->{'table'},
                          -column=>$con->{'column'},
                          -value=>$rec->{'id'},
                      });
                      last SWITCH;
                  };
                  Utility::redError("table->{'table'} metadata has invalid rel type \"$con->{'type'}\"");
              };
            }
        }
    }
}




##################################################################
##
## Enumerated type utility functions
##
##  EnumsList - returns an array of values corresponding to the
##              domain values of an enumerated type column in a table.
##              my @enums = EnumsList("tasks", "priority");
##



sub EnumsList($$)
{
    my ($table, $column) = (@_);
    SQLSend("SHOW COLUMNS FROM $table LIKE '$column'");
    my @result = SQLFetchData();
    my $str = $result[1];
    $str =~ s/enum\(//;
    my @enums = ($str =~ /'(\w+)'[,)]/gi);
return @enums;
}

sub SetList($$)
{
    my ($table, $column) = (@_);
    SQLSend("SHOW COLUMNS FROM $table LIKE '$column'");
    my @result = SQLFetchData();
    my $str = $result[1];
    $str =~ s/set\(//;
    my @enums = ($str =~ /'(\w+)'[,)]/gi);
return @enums;
}
1;

