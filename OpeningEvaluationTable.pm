# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use EvaluationTable;
use OpeningTable;

%::OpeningEvaluationTable = (
    table => "opening_evaluation",
    heading => "Opening-Evaluation Join",
    columns => [
	{
	    column => "id",
	    heading => "Id",
	    type => "pk",
	},
	{
	    column => "opening_id",
	    heading => "Opening",
	    type => "fk",
	    values => {
		table => \%::OpeningTable,
		pk => "id",
		label => "description",
	    },
	},
	{
	    column => "evaluation_id",
	    heading => "Evaluation Form",
	    type => "fk",
	    values => {
		table => \%::EvaluationTable,
		pk => "id",
		label => "title",
	    },
	},
    ],
    
    );
1;
