#!/usr/bin/perl
use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard -nosticky *table *Tr);
use Data::Dumper;

BEGIN {push @INC, "..";}

require "globals.pl";

use Login;
use Audit;
use Changes;
use Database;
use Layout;
use OptionMenuWidget;

use ActionTable;
use CandidateTable;
use CommentTable;
use DocumentTable;
use FrontlinkTable;
use UserTable;
use KeywordTable;
use OpeningTable;
use SuggestionTable;
use InterviewTable;
use InterviewSlotTable;
use AuditTable;
use ParamTable;
use DepartmentTable;
use CronTable;


print header;
print start_html, "\n";

ConnectToDatabase();

print p(b("Form menus, enums, select one, no default")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::CandidateTable,
    -form=>"XXX",
    -column=>"status",
}), "\n";
print PulldownMenu({-table=>\%::CandidateTable,
				  -column=>"status",
			  }), "\n";

print p(b("Form menus, enums, select multiple, no default")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::CandidateTable,
    -column=>"status",
    -form=>"XXX",
    -multiple=>1,
}), "\n";

print p(b("Form menus, enums, given default")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::CandidateTable,
    -column=>"status",
    -form=>"XXX",
    -default=>"ACTIVE",
}), "\n";
print PulldownMenu({-table=>\%::CandidateTable,
				  -column=>"status",
				  -default=>"ACTIVE",
			  }), "\n";

print p(b("Form menus, enums, include null")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::CandidateTable,
    -column=>"status",
    -form=>"XXX",
    -null=>"--nothing--",
}), "\n";
print PulldownMenu({-table=>\%::CandidateTable,
				  -column=>"status",
				  -null=>"--nothing--",
			  }), "\n";

print hr, "\n";
#------------------------------------------------------------------
print p(b("Form menus, DB column")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::ActionTable,
    -column=>"action",
    -form=>"XXX",
}), "\n";
print PulldownMenu({-table=>\%::ActionTable,
				  -column=>"action",
			  }), "\n";

print p(b("Form menus, DB column, select multiple")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::ActionTable,
    -column=>"action",
    -form=>"XXX",
    -multiple=>1,
}), "\n";

print p(b("Form menus, DB column, given default")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::ActionTable,
    -column=>"action",
    -form=>"XXX",
    -default=>7,
}), "\n";
print PulldownMenu({-table=>\%::ActionTable,
				  -column=>"action",
				  -default=>7,
			  }), "\n";

print p(b("Form menus, enums, include null")), "\n";
print OptionMenuWidget::widget({
    -table=>\%::ActionTable,
    -column=>"action",
    -form=>"XXX",
    -null=>"--nothing--",
}), "\n";
print PulldownMenu({-table=>\%::ActionTable,
				  -column=>"action",
				  -null=>"--nothing--",
			  }), "\n";

print hr, "\n";
#------------------------------------------------------------------

print p(b("Form menus, bit vector"));
print OptionMenuWidget::widget({
    -table=>\%::CronTable,
    -column=>"dow",
    -form=>"XXX",
});
print PulldownMenu({-table=>\%::CronTable,
				   -column=>"dow",
			   });

print p(b("Form menus, bit vector, select multiple"));
print OptionMenuWidget::widget({
    -table=>\%::CronTable,
    -column=>"dow",
    -form=>"XXX",
    -multiple=>1,
});

print end_html, "\n";
