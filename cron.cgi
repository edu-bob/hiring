#!/usr/bin/perl -w
# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use CGI qw(-nosticky :standard *table *td *Tr *ol *ul *Tr);
use CGI::Carp qw(fatalsToBrowser);

require "globals.pl";

use InterviewTable;
use ParamTable;
use CronTable;

use Query;
use Database;
use Layout;
use OptionMenuWidget;
use CronTable;

use Data::Dumper;

if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "weekly" and do {
          
          last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
    print header;
    my $col = Layout::findColumn({-table=>\%::CronTable, -column=>"dom"});
#    print p("dom ref is ", ref($col->{'labels'}));
    $col = Layout::findColumn({-table=>\%::CronTable, -column=>"dow"});
#    print p("dow ref is ", ref($col->{'labels'}));
#    print Utility::ObjDump(\%::CronTable);
    doAddForm();
}

sub doRun()
{
    print header, start_html({-title=>"Scheduled Events"});
    my @names = param;
#    print h4("in doRun"), "\n";
#    foreach my $n ( @names ) {
#        if ( $n !~ /^Url/ ) {
#            print "$n = ", param($n), br;
#        }
#    }

    my $action = param("action");
    my $name = param("name");
    my $dir = param("dir");
  SWITCH: {
      if ( !defined $action ) {
          print p(b("BOTCH: \"action\" parameter is not defined."));
          last SWITCH;
      }
      defined $action && $action eq "Del" && do {
          print h1("Delete a Query"), hr, "\n";
          doReadAll($dir) or do {
              last SWITCH;
          };
          my $rec = findEntry($name);
          if ( $rec ) {
              my $fullfile = "$::QDIR/$dir/$$rec{file}";
              unlink($fullfile) or do {
                  print p(b("unlink $fullfile: $!"));
                  last SWITCH;
              };
              print p(b("$fullfile removed."));
          } else {
              print p(b("Cannot find $name"));
          }
          last SWITCH;
      };
      defined $action && $action eq "Edit" && do {
          doReadAll($dir) or do {
              last SWITCH;
          };
          my $rec = findEntry($name);
          if ( $rec ) {
              doEdit($rec, $dir);
          } else {
              print p(b("Cannot find $name"));
          }
          last SWITCH;
      };
  };
    print footer();
    print end_html;
}

sub findEntry
{
    my $name = shift;
    foreach $rec ( @::QUERIES ) {
        if ( $$rec{type} eq "file" && $$rec{entry}->{name} eq $name ) {
            return $rec;
        }
    }
    return undef;
}

sub doEdit
{
    my $rec = shift;
    my $dir = shift;
    print h1("Edit a Query"), hr;
    print start_form;
    param("op", "edit");
    print hidden({-name=>"op", -default=>"edit"});
    print hidden({-name=>"dir", -default=>"$dir"});
    doAddForm($rec);
    print submit({-name=>"Submit"});
    print end_form;
}

sub doAdd
{
    my $isnew = shift;

    my $header = <<'EOF';
##
## Fields in the query structure:
##
##    name ...... the name of the query as given by its creator
##    url ....... the URL of the query
##    enabled ... 1==enabled
##    daytype ... type of day-to-run: every,dow,dom
##    dow ....... if daytype==dow, array of days-of-the-week, 0==Sunday, 1==Monday, ...
##    dom ....... if daytype==dom, array of days-of-the-month
##    time ...... times to run, in minutes since midnight
##
EOF

    print header, start_html({-title=>"Scheduled Bug Reports"});

  BODY: {
      print h1(($isnew ? "Add" : "Edit" ) . " a New Query"), hr;
      
      my $opt_name = param("name");
      my $opt_enabled = param("enabled");
      my $opt_url = param("url");
      my $opt_daytype = param("daytype");
      my @opt_dow = param("dow");
      my @opt_dom = param("dom");
      my @opt_time = param("time");
      my $opt_dir = param("dir");
      
      my $query;
      $query->{name} = $opt_name;
      $query->{url} = $opt_url;
      $query->{enabled} = $opt_enabled;
      $query->{daytype} = $opt_daytype;
    SWITCH: {
        $opt_daytype eq "dow" && do {
            $query->{dow} = [ @opt_dow ];
            last SWITCH;
        };
        $opt_daytype eq "dom" && do {
            $query->{dom} = [ @opt_dom ];
            last SWITCH;
        };
    };
      $query->{time} = [ @opt_time ];
      my $filename = filename_sanitize($opt_name);
#      print Utility:Dumper($query);
      my $fullfilename = "$::QDIR/$opt_dir/$filename.pl";

      if ($isnew && -f $fullfilename ) {
          print p(b("Error: $filename already exists - delete it first."));
          last BODY;
      }

      open FH, ">$fullfilename" or do {
          print p(b("Error: $fullfilename: $!"));
          last BODY;
      };
      print FH $header,Dumper($query);
      close FH;
      print p("$opt_name: Successfully saved in $opt_dir.");
  };
    print footer();
    print end_html;
}

##
## doAddForm - generate the "Add/Edit" form
##
## Context: The start_form was issued by the caller.
##

sub doAddForm
{
    my $rec = shift;
    my $entry;
    defined $rec and $entry = $$rec{entry};
    
#    if ( defined $rec ) {
#        print Utility::ObjDump($rec);
#    }
    print start_table({-border=>"1", -cellspacing=>"0", -cellpadding=>"8"});
    print start_Tr;
    print td("Name: ");
    print start_td;
    print textfield({-name=>"name",
                     -size=>"40",
                     -default=>($rec ? $entry->{name} : "")});
    if ( defined $rec && !$entry->{enabled} ) {
        print checkbox({-name=>"enabled",
                        -label=>"Enabled",
                        -value=>"1"});
    } else {
        print checkbox({-name=>"enabled",
                        -label=>"Enabled",
                        -checked=>"true",
                        -value=>"1"});
    }
    print end_td, end_Tr;
    
    print Tr(
             td({-colspan=>"2", -align=>"center"}, b("When to execute")));
    print start_Tr, "\n";
    print td("Days:"), "\n";
    print start_td, "\n";
    
    my %def_daytype;
    $def_daytype{every} = "";
    $def_daytype{dow} = "";
    $def_daytype{dom} = "";
    if ( defined $rec ) {
        $def_daytype{$entry->{daytype}} = "checked";
    } else {
        $def_daytype{every} = "checked";
    }
    print start_table({-border=>"0"}), "\n";
    print Tr(td({-colspan=>"2"},
                "<input type=\"radio\" name=\"daytype\" $def_daytype{every} value=\"every\">",
                "Every day")), "\n";
    
    
    ## Day of the week option
    
    my $def_dow;
    if ( defined $rec && $entry->{daytype} eq "dow" ) {
        $def_dow = $entry->{dow};
    } else {
        $def_dow = [];
    }
    print Tr(
             td("<input type=\"radio\" name=\"daytype\" $def_daytype{dow} value=\"dow\">",
                "Days of the week"),
             td(OptionMenuWidget::widget({-table=>\%::CronTable, -column=>"dow", -multiple=>1,
                            -default=>$def_dow,
                            -onchange=>"document.addform.daytype[1].checked=1;document.addform.daytype.value=\"dow\";",
                        }))
             ), "\n";
    
    ## Day of the month option
    
    my $def_dom;
    if ( defined $rec && $entry->{daytype} eq "dom" ) {
        $def_dom = $entry->{dom};
    } else {
        $def_dom = [];
    }
    print Tr(
             td("<input type=\"radio\" name=\"daytype\" $def_daytype{dom} value=\"dom\">",
                "Days of the month"),
             td(OptionMenuWidget::widget({-table=>\%::CronTable, -column=>"dom",
                            -multiple=>"true",
                            -default=>$def_dom,
                            -onchange=>"document.addform.daytype[2].checked=1;document.addform.daytype.value=\"dom\";"
                            }))
             ), "\n";
    
    print end_table, "\n";
    
    print end_td, "\n";
    print end_Tr, "\n";
    
    ## Time of Day entry
    
    
    my $def_time;
    if ( defined $rec ) {
        $def_time = $entry->{time};
    } else {
        $def_time = [];
    }
    
    print Tr(
             td("Times:"),
             td(OptionMenuWidget::widget({-table=>\%::CronTable, -column=>"time",
                           -multiple=>"true",
                           -default=>$def_time})));
    
    print end_table, "\n";
}

sub printable_time
{
    my $val = shift;
    my $hour = int($val/60);
    my $minute = $val%60;
    return sprintf("%d:%02d %s",
            $hour > 12 ? ($hour-12) : $hour,
            $minute,
            ($hour==0 && $minute==0) ? "midnight" :
            ($hour==12 && $minute==0) ? "noon" :
            $hour < 12 ? "a.m." : "p.m." );
}

##
## filename_sanitize - convert a query name into a usable filename
##


sub filename_sanitize
{
    my $name = shift;
    my $filename = $name;
    $filename =~ s/[^-#@%.,+A-Za-z0-9_]/_/g;
    return $filename;
}

sub footer
{
    my $url = url({-relative=>1});
    return  hr . a({-href=>"$url"}, "Scheduled Reports Home");
}

##################################################################
##
## main
##

my $dir;
if ( !defined param("dir") ) {
    $dir = ".";
} else {
    $dir = param("dir");
}

if ( defined param("op") ) {
    my $value = param("op");
  SWITCH: {
      $value eq "run" && do {  # "run" has a further modifier "action"
          doRun();
          last SWITCH;
      };
      $value eq "add" && do {
          doAdd(1);
          last SWITCH;
      };
      $value eq "edit" && do {
          doAdd(0);
          last SWITCH;
      };
      $value eq "adddir" && do {
          doAddDir();
          last SWITCH;
      };
  };
} else {
    doMainPage($dir);
}
