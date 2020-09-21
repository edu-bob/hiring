# -*- Mode: perl; indent-tabs-mode: nil -*-
package Calendar;


use strict;
use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);
use CGI::Carp qw(fatalsToBrowser);;

use CGI qw(:standard *table *Tr *td);

=head1 NAME

calendar - create a HTML calendar

=head1 SYNOPSIS

  Note: this is an OO interface

    use Calendar

    my $ch = new Calendar

=head1 DESCRIPTION

=over 4

=item Calendar::new

=back

=cut


use 5.00;
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "1.00";
require Exporter;
@ISA=('Exporter');

## Default eported symbols
@EXPORT = qw();
## Optional exported symbols
@EXPORT_OK = qw();


my $SPD = (24*60*60);

use Date::Manip qw(ParseDate UnixDate);
use Argcvt;
use Utility;


##
## new();
##
## Parameters
##    smallWeekends = true .... weekend columns are narrower
##                    false ... weekend columns are the same size as weekdays
##    grayWeekends = true .... make weekend columns gray
##                   false ... make weekend days the same as weekdays
##    startDate = start date in SQL datetime format
##    endDate = end date in SQL format
##    type = passed through to the doDay function
##    func = function to call to render each day contents
##

sub new
{
    my ($junk, $argv) = (@_);
    argcvt($argv, ['startdate', 'enddate'], ['grayweekends', 'smallweekends', 'type', 'func']);

    my $self = {};
    $self->{'startdate'} = $$argv{'startdate'};
    $self->{'enddate'} = $$argv{'enddate'};
    $self->{'grayweekends'} = $$argv{'grayweekends'};
    $self->{'smallweekends'} = $$argv{'smallweekends'};
    $self->{'type'} = $$argv{'type'};
    $self->{'func'} = $$argv{'func'};
    bless $self;
    return $self;
}

sub render
{
    my ($self, $argv) = (@_);

    my $result = "";

  BODY: {
      my ($year0, $month0, $day0, $time0, $dow0);
      my ($year1, $month1, $day1, $time1, $dow1);

      if ( $self->{'smallweekends'} ) {
          $self->{'weekendwidth'} = 5;
          $self->{'weekdaywidth'} = int((100-$self->{'weekendwidth'}*2)/5);
      } else {
          $self->{'weekendwidth'} = int(100/7);
          $self->{'weekdaywidth'} = int(100/7);
      }

      my $date0 = ParseDate($self->{'startdate'});
      if (!$date0) {
		  print p(b("Bad start date")), "\n";
		  last BODY;
      } else {
		  ($dow0, $time0, $year0, $month0, $day0) = UnixDate($date0, "%w", "%s", "%Y", "%m", "%d");
      }
	  $time0 += (12*60*60);
      my $date1 = ParseDate($self->{'enddate'});
      if (!$date1) {
		  print p(b("Bad start date")), "\n";
		  last BODY;
      } else {
		  ($dow1, $time1, $year1, $month1, $day1) = UnixDate($date1, "%w", "%s", "%Y", "%m", "%d");
      }
      $time1 += (12*60*60);

      my $result = "";

      $result .= start_table({-width=>"100%", -border=>"1", -cellspacing=>"0"}) . "\n";
      $result .= $self->weekdayHeader();
      $result .= $self->monthHeader($time0) . "\n";
      
      ## Compute the time of the beginning of the week
      
      my $dow = $self->dowOf($time0);
      my $bow = $time0 - $dow*$SPD;
      my $curtime = $bow;
      my $curmonth = $self->monthOf($time0);
      
      while ( $curtime <= $time1 ) {
		  $result .= start_Tr;
		  
		  ## Handle first line of the calendar
		  
		  if ( $curtime < $time0 ) {
			  my $dow = $self->dowOf($time0);
			  if ( $dow > 0 ) {
				  $result .= $self->grayDays(0, $dow);
			  }
			  $curtime += $dow*$SPD;
		  }
		  
		  ## Now handle some real days, through end of week
		  while ( $curtime <= $time1 ) {
			  if ( $self->monthOf($curtime) != $curmonth ) {
				  $result .= $self->grayDays($self->dowOf($curtime),7) . "\n";
				  $curmonth = $self->monthOf($curtime);
				  $result .= $self->monthHeader($curtime) . "\n";
				  $result .= $self->grayDays(0, $self->dowOf($curtime)) . "\n";
			  }
			  if ( $self->{'func'} ) {
			      $result .= $self->doDay($curtime, $self->{'type'}) . "\n";
			  }
			  $curtime += $SPD;
			  if ( $self->dowOf($curtime) == 0 ) {
				  last;
			  }
		  }
		  
		  if ( $curtime > $time1 ) {
			  if ( $self->dowOf($curtime) != 0 ) {
				  $result .= $self->grayDays($self->dowOf($curtime), 7);
			  }
		  }
		  $result .= end_Tr . "\n";
      }
	  
      $result .= end_table . "\n";
#      if ( $NumCancelled ) {
#	  $result .= p("Entries in italics are interviews that were cancelled.");
#      }
      return $result;
  };
}



sub weekdayHeader
{
    my $self = shift;
    return Tr(
	      th({-width=>"$self->{'weekendwidth'}%"}, u($self->{'smallweekends'}? "Sun" : "Sunday")), "\n",
	      th({-width=>"$self->{'weekdaywidth'}%"}, u("Monday")), "\n",
	      th({-width=>"$self->{'weekdaywidth'}%"}, u("Tuesday")), "\n",
	      th({-width=>"$self->{'weekdaywidth'}%"}, u("Wednesday")), "\n",
	      th({-width=>"$self->{'weekdaywidth'}%"}, u("Thursday")), "\n",
	      th({-width=>"$self->{'weekdaywidth'}%"}, u("Friday")), "\n",
	      th({-width=>"$self->{'weekendwidth'}%"}, u($self->{'smallweekends'} ? "Sat" : "Saturday")), "\n",
	      ) . "\n";
}

sub monthHeader
{
    my ($self,$time) = (@_);
    my @MONTHS = (
		  "January",
		  "February",
		  "March",
		  "April",
		  "May",
		  "June",
		  "July",
		  "August",
		  "September",
		  "October",
		  "November",
		  "December",
		  );
    
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime($time);
    return Tr(
	      td({-width=>"100%", -colspan=>"7", -bgcolor=>"#000000", -align=>"center"},
		 font({-color=>"#FFFFFF", -size=>"+1"}, b(uc($MONTHS[$month]) . ",", 1900+$year)))) . "\n";
}


sub grayDays
{
    my ($self, $day0, $day1) = (@_);

    if ( $day0 == $day1 ) {
	return;
    }
    my $width = 0;
    for ( my $day=$day0 ; $day < $day1 ; $day++ ) {
	$width += ($day==0 || $day==6? $self->{'weekendwidth'} : $self->{'weekdaywidth'});
    }
    my $colspan = $day1-$day0;
    return td({-width=>"$width%", -bgcolor=>"#C0C0C0", -colspan=>"$colspan"}, "&nbsp;") . "\n";
}


sub monthOf
{
    my ($self, $time) = (@_);

    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime($time);
    return $month;
}

sub dowOf
{
    my ($self, $time) = (@_);
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime($time);
    return $wday;
}

sub dateOf
{
    my ($self,$time) = (@_);

    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
		$wday, $yday, $isdst) = localtime($time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d (%d)", 1900+$year, $month+1, $day_of_month, $hours, $minutes, $seconds, $wday);
}

sub doDay
{
    my ($self, $time, $type) = (@_);
    my ($seconds, $minutes, $hours, $day_of_month, $month, $year,
	$wday, $yday, $isdst) = localtime($time);
    my ($today_seconds, $today_minutes, $today_hours, $today_day_of_month, $today_month, $today_year,
	$today_wday, $today_yday, $today_isdst) = localtime(time);

    my $istoday = ($year==$today_year && $month==$today_month && $day_of_month==$today_day_of_month);

    my $width;
    my $color;
    if ( $wday == 0 || $wday == 6 ) {
		$width = $self->{'weekendwidth'};
		$color = ($istoday? ($self->{'grayweekends'} ? "#C0F0C0" : "#CCFFCC") : ($self->{'grayweekends'} ? "#C0C0C0" : "#FFFFFF"));
    } else {
		$width = $self->{'weekdaywidth'};
		$color = ($istoday? "#CCFFCC" : "#FFFFFF");
    }
    my $content = $self->{'func'}($time, $type);
    return td({-width=>"$width%", -valign=>"top", -bgcolor=>"$color"}, "\n",
	      table({-border=>"0", -width=>"100%", -cellspacing=>"0"},
		    Tr(
		       td({-width=>"100%", -valign=>"top", -bgcolor=>"$color"}, p({-align=>"right"},font({-size=>"2"}, $day_of_month)))), "\n",
		    Tr(
		       td({-width=>"100%", -bgcolor=>"$color"}, $content ? $content : "&nbsp;"))
		    )
		  );
}


sub getURL
{
    my ($argv) = (@_);

    argcvt($argv, ['startdate', 'enddate'], ['grayweekends', 'smallweekends', 'type']);
    my $url = "calendar.cgi?op=go;start=$$argv{'startdate'};end=$$argv{'enddate'}";
    if ( defined $$argv{'type'} ) {
        $url .= ";type=$$argv{'type'}";
    } else {
        $url .= ";type=user";
    }
    if ( defined $$argv{'grayweekends'} ) {
        $url .= ";grayweekends=$$argv{'grayweekends'}";
    }
    if ( defined $$argv{'smallweekends'} ) {
        $url .= ";smallweekends=$$argv{'smallweekends'}";
    }
    
    return $url;
}


1;
