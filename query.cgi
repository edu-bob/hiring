#!/usr/bin/perl -w
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use Getopt::Std;
use CGI qw(:standard -nosticky *table *Tr *td);
use CGI::Carp qw(fatalsToBrowser);

require "globals.pl";

use UserTable;
use ActionTable;
use OpeningTable;
use CandidateTable;
use DepartmentTable;

use Application;
use Query;
use Database;
use Layout;
use Login;
use Candidate;
use User;
use Comment;
use Utility;


my @Standard = (
		{
		    heading => "ID",
		    url => "id",
		    field => 'id',
		    align => "right",
		},
		{
		    heading => "Name",
		    url => 'name',
		    field => 'name',
		    link => \&Candidate::candidateURL,
                    warpable => 1,      # means that this url can be warped to if only one result is returned
		},
		{
		    heading => "Status",
		    url => 'status',
		    field => 'status',
		},
		{
		    heading => "Next Action",
		    url => 'action_id',
		    field => 'action_id.action',
		},
		{
		    heading => "Owner",
		    url => 'owner',
		    field => 'owner_id.name',
		},
		{
		    heading => "Age",
		    url => 'age',
		    field => 'agestr',
                    nowrap => "1",
		},
		{
		    heading => "Rating",
		    url => 'ratings',
		    field => 'ratings',
		    align => "right",
		    format => "%.2f",
		},
		{
		    heading => "Coms",
		    url => 'comments',
		    field => 'commentstr',
		    align => "center",
		},
		{
		    heading => "Docs",
		    url => 'documents',
		    field => 'documents',
		    align => "center",
		},
		{
		    heading => "Info?",
		    field => 'havecontact',
		    align => "center",
		    type => "YN",
		},
		{
		    heading => "Position",
		    url => 'position',
		    field => 'opening_id.description',
		},
		{
		    heading => "Referred By",
		    value => \&Candidate::getReferrer,
                    field => "referrer",
                    url => "referrer",
		},

		);

my @Recruiter = (
		 {
		     heading => "ID",
		     url => "id",
		     field => 'id',
		     align => "right",
		 },
		 {
		     heading => "Name",
		     url => 'name',
		     field => 'name',
#		     link => \&Candidate::candidateURL,
                    warpable => 1,      # means that this url can be warped to if only one result is returned
		 },
		 {
		     heading => "Status",
		     url => 'status',
		     field => 'status',
		 },
		 {
		     heading => "Next Action",
		     url => 'action_id',
		     field => 'action_id.action',
		 },
		 {
		     heading => "Age",
		     url => 'age',
		     field => 'agestr',
                     nowrap => "1",
		 },
		 {
		     heading => "Info?",
		     field => 'havecontact',
		     align => "center",
		     type => "YN",
		 },
		 {
		     heading => "Position",
		     url => 'position',
		     field => 'opening_id.description',
		 },
		 {
		     heading => "Referred By",
		     value => \&Candidate::getReferrer,
                     url => "referrer",
                     field => "referrer",
		 },
		 {
		     heading => "Ref #",
			 field => "recruiter_ref",
			 align => "right",
		     },
		 );

my %Format = (
	      "standard" => {
                  columns => \@Standard,
                  nolinks => 0,
              },
	      "recruiter" => {
                  columns => \@Recruiter,
                  nolinks => 1,
              },
              "long" => {
                  columns => \@Standard,
                  nolinks => 0,
              },
	      );

Application::Init();

# In must-log-in mode, make sure we're logged in

my $mustLogIn = Param::getValueByName('must-log-in');
if ( $mustLogIn && ref $mustLogIn ) {
    $mustLogIn = $mustLogIn->{'value'};
}
if ( $mustLogIn && !isLoggedIn() ) {
    doMustLogin(self_url());;
}


if ( param("op") && param("op") eq "go" ) {
    doGo();
    exit(0);
}


if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "query" and do {
          doQuery();
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
    ConnectToDatabase();
    my $jscript = Query::getJavaScript();
    print doHeading({-title=>"Query Candidates",
		     -script=>$jscript,
		     -onload=>"selectDepartment(document.forms['queryform']);"});

    ## Make query form
    print Layout::startForm({-name=>"queryform"});;
    print hidden({-name=>"op", -default=>"go"});
    print Query::standardForm("queryform");
    print table({-cellpadding=>3},
		Tr(
		   td({-valign=>"top"}, 
		      checkbox({-name=>"sfa", -value=>1, -label=>"Group by Next Action"}),
		      br,
		      checkbox({-name=>"nolinks", -value=>1, -label=>"Omit all links (default for recruiter mode)"})),
		   td("&nbsp;&nbsp;&nbsp;&nbsp;"),
		   td({-valign=>"top", -align=>"right"}, "Format: ",),
		   td({-valign=>"top"}, radio_group({-name=>"format",
						     -values=>['standard', 'recruiter', 'long'],
						     -linebreak=>'true',
						     -labels=>{'standard'=>"Standard",
							       'recruiter'=>"Recruiter",
							       'long'=>"Long"}})),)
		);
    print br(),submit({-name=>"Search"}), "&nbsp;", reset({-name=>"Clear Form"}), "\n";
    print Layout::endForm;
    print Footer(),"\n";
    print end_html, "\n";
}


sub doGo
{
    my $q = new CGI;
    $q->param("op", "query");
    $q->delete("Search");
    print $q->redirect(-location=>$q->self_url(), -method=>"get");
}

##
## Process the "Search" command from the main query page
##

sub doQuery
{
    my $lastURL = undef;

    my $format = param("format");
    if ( !defined $format ) {
	$format = "standard";
    }

    my $self_url = self_url();
    my $sfa;
    my $sort = param("sort");
    my $sortorder = param("sortorder");
    if (defined param("sfa") ) {
	if ( defined $sort ) {
	    if ( $sort =~ /^action_id/ ) {
		$sfa = 1;
	    } else {
		$sfa = 0;
	    }
	} else {
	    $sfa = 1;
	    $sort = "action_id.precedence-n";
	}
    } else {
	$sfa = 0;
    }

    ## These are the sort urls for the column headings

    my %sorturl;

    my $nolinks = (defined param("nolinks") && param("nolinks")) || $Format{$format}->{'nolinks'};
    my $cookie = cookie({-name=>"query",
			 -value=>self_url()});

# Make various sorting URLs

    if ( $sortorder ) {
	param("sortorder", 0);
    } else {
	param("sortorder", 1);
    }

    param("sort", "id-n");
    $sorturl{'id'} = self_url();

    param("sort", "name");
    $sorturl{'name'} = self_url();

    param("sort", "status");
    $sorturl{'status'} = self_url();

    param("sort", "comments-n");
    $sorturl{'comments'} = self_url();

    param("sort", "documents-n");
    $sorturl{'documents'} = self_url();

    param("sort", "ratings-n");
    $sorturl{'ratings'} = self_url();

    param("sort", "action_id.precedence-n");
    $sorturl{'action_id'} = self_url();

    param("sort", "owner_id.name");
    $sorturl{'owner'} = self_url();

    param("sort", "opening_id.description");
    $sorturl{'position'} = self_url();

    param("sort", "age-n");
    $sorturl{'age'} = self_url();

    param("sort", "referrer");
    $sorturl{'referrer'} = self_url();

    ConnectToDatabase();



    print header({-cookie=>"$cookie"});;

    print doHeading({-title=>"Query Candidates Results"});


    my ($query, $hashes) = Query::makeQuery({  });

    ##
    ## XXX: if include_cc is selected, also get candidates who have the owner_id in the CC table
    ##

    if ( param("include_cc") ) {
    } else {
    }
    my @results = Query::extendedResults($query, $hashes);
#    print Utility::ObjDump(\@results);

    ##
    ## After the results have been gathered, make a pass over the table format description and fill in any dynamic
    ## entries as needed (unimplemented)
    ##

    foreach $r ( @results ) {
	foreach my $c ( @{$Format{$format}->{'columns'}} ) {
	    if ( exists $$c{'value'} ) {
              SW1: {
                # check for an external call
                  ref $$c{'value'} eq 'CODE' and do {
                      ## CODE values result in calling the procedure with the candidate record
                      ## as the argument.  
                      $r->{$$c{'field'}} = &{$$c{'value'}}($r);
                      last SW1;
                  };
                  $r->{$$c{'field'}} = $$c{'value'};
              };
	    } 
	}
    }

    if ( $sort ) {
	if ( $sort =~ /-n$/ ) {
	    $sort =~ s/-n$//;
	    if ( $sortorder ) {
		@results = sort {
		    $a && $a->{$sort} ?
                        ( $b && $b->{$sort} ?
                          $b->{$sort} <=> $a->{$sort} : -1 ) :
                          ( $b ? 1 : 0 ) } @results;
	    } else {
		@results = sort {
		    $a && $a->{$sort} ?
                        ( $b && $b->{$sort} ?
                          $a->{$sort} <=> $b->{$sort} : -1 )
                        : ( $b ? 1 : 0 ) } @results;
	    }
	} else {
	    if ( $sortorder ) {
		@results = sort {$b->{$sort} cmp $a->{$sort} } @results;
	    } else {
		@results = sort {$a->{$sort} cmp $b->{$sort} } @results;
	    }
	}
    }
    my $row = 0;
    my $color;
    my $lastaction = "impossible";
    foreach $r ( @results ) {
	my $doheading = 0;
	if ( $sfa ) {
	    my $thisaction = (!defined $r->{'action_id'} || !$r->{'action_id'} ? 0 : $r->{'action_id'} );
	    if ( $lastaction ne $thisaction ) {
		print end_table, br;
		print table({-border=>"0", -cellspacing=>"6", -cellpadding=>"4", -width=>"100%"},
			    Tr(
			       td({-bgcolor=>"#ffffff", -valign=>"bottom"},
				  font({-size=>"4"},
				       ("Next Action: ", $r->{'action_id.action'} ? $r->{'action_id.action'} : "none specified"),
				       ))));
		$lastaction = $thisaction;
		$doheading = 1;
		$row = 0;
	    }
	} else {
	    if ( $lastaction eq "impossible" ) {
		$doheading = 1;
		$lastaction = "x";
	    }
	}
	if ( $doheading ) {
	    print start_table({-width=>"100%", -cellspacing=>"0", -cellpadding=>"2"});
	    print start_Tr;
	    foreach my $c ( @{$Format{$format}->{'columns'}} ) {
		my $str = b($c->{'heading'});
		if ( !$nolinks ) {
		    if ( exists $$c{'url'} ) {
			$str = a({-href=>$sorturl{$$c{'url'}}}, $str);
		    }
		}
		if ( exists $$c{'align'} ) {
		    $str = td({-align=>$$c{'align'}}, $str);
		} else {
		    $str = td($str);
		}
		print "$str\n";
	    }
	    print end_Tr;

	}

	if ( $row%2 ) {
	    $color = "#ffffff";
	} else {
	    $color = "#ddffdd";
	}
	$row++;
	foreach my $c ( @{$Format{$format}->{'columns'}} ) {
	    my %colargs = ( -bgcolor=>$color );
	    if ( exists $$c{'align'} ) {
		$colargs{-align} = $$c{'align'};
	    }
            if ( exists $$c{'nowrap'} ) {
                $colargs{-nowrap} = $$c{'nowrap'}
            }
	    my $str = "";
	    if ( exists $$c{'type'} ) {
	      SW: {
		  $$c{'type'} eq "YN" and do {
		      $str .= ($$c{'field'} && $$r{$$c{'field'}} ? "Y" : "N");
		      last SW;
		  };
	      };
	    } elsif ( exists $$c{'format'} ) {
		if (  $$c{'field'} && $$r{$$c{'field'}} ) {
		    $str .= sprintf($$c{'format'}, $$r{$$c{'field'}});
		} else {
		    $str .= "\&nbsp;";
		}
            } else {
		if ( $$c{'field'} &&  $$r{$$c{'field'}} ) {
		    $str .= $$r{$$c{'field'}};
		}
	    }
	    if ( !$nolinks && exists $$c{'link'} ) {
		my $linkurl = &{$$c{'link'}}($$r{'id'});;
		$str = a({-href=>$linkurl}, $$r{$$c{'field'}});
                if ( exists $$c{'warpable'} ) {
                    $lastURL = $linkurl;
                }
	    }

	    print td(\%colargs, $str? $str : "&nbsp;"), "\n";
	}
	print end_Tr;

    }
    print end_table;

    ##
    ## If the "long" format was selected, then generate the long report on each candidate as well
    ##

    if ( $format eq "long" ) {
	foreach $r ( @results ) {
	    print hr, "\n";
	    my $candidate = Candidate::getRecord($r->{'id'});
	    ## TODO: Make this heading a link to the detail page
	    print h2(Candidate::candidateLink({
		-id=>$r->{'id'},
		-target=>"_blank"
					     }));
	    print doStaticValues({
		-record => $candidate,
		-table => \%::CandidateTable,
		-skipempty => 1,
	    });
	    print h3("Ratings");
	    print Candidate::formatRatings($r->{'id'});
	    print h3("Schedules"), "\n";

	    my @schedules = getRecordsMatch({
		-table=>\%::InterviewTable,
		-column=>"candidate_id",
		-value=>$r->{'id'},
	    });
	    if ( scalar @schedules == 0 ) {
		print p("None.");
	    } else {
		print start_table({-cellpadding=>"4"});
		print Tr(
			 td(b("When")),
			 td(b("Status")),
			 td(b("Who")),
			 td(b("Description")),
			 );
		foreach my $s ( @schedules ) {
		    print start_Tr, "\n";
		    print td({-valign=>"top"}, $s->{'date'}), "\n";
		    print td({-valign=>"top"}, $s->{'status'}), "\n";
		    print start_td({-valign=>"top"}), "\n";
		    my $interviewers = Schedule::getInterviewers($s->{'id'});
		    my $lines_printed = 0;
		    foreach my $interviewer_name ( keys %$interviewers ) {
			$lines_printed++ && print br;
			print User::getName($interviewer_name), "\n";
		    }
		    print end_td, "\n";
		    print td({-valign=>"top"}, $s->{'purpose'}), "\n";
		    print end_Tr, "\n";
		}
		print end_table;
	    }

	    print h3("Comments");
	    my @comments = getRecordsMatch({
		-table=>\%::CommentTable,
		-column=>"candidate_id",
		-value=>$r->{'id'},
	    });
	    foreach my $c ( @comments ) {
		my $username = User::getName($c->{'user_id'});
		print h4("By $username on $c->{'creation'}");
		print p(Utility::cvtTextarea($c->{'comment'}));
	    }
	}

    }

    ##
    ## If there was only one result, then warp off to the last warpable URL that was seen in
    ## the table.
    if ( scalar(@results) == 1 && $lastURL ) {
        print script("document.location = '$lastURL'");
    }
    print p(scalar(@results) . " result" . (scalar(@results)!=1?"s":"") .
            (!isAdmin() ? " (others may be hidden)" : "") . ".");
    print Footer({-url=>"self_self_url"});
    print end_html, "\n";
}

