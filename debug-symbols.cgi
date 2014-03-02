#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use strict;
use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img -nosticky);
use CGI::Carp;
use Login;

require "globals.pl";
use FrontlinkTable;
use ParamTable;




print header;

print h2("\%main::");
foreach my $k ( sort keys %main:: ) {
	print "\$main::{$k} = $main::{$k}", br;
}

print h2("\%Login::");
foreach my $k ( sort keys %Login:: ) {
	print "\$Login::{$k} = $Login::{$k}", br;
}
