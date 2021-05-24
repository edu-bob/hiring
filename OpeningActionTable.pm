# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use ActionTable;
use OpeningTable;

%::OpeningActionTable = (
    table => "opening_action",
    heading => "Opening-Action Join",
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
	    column => "action_id",
	    heading => "Action",
	    type => "fk",
	    values => {
		table => \%::ActionTable,
		pk => "id",
		label => "action",
	    },
	},
    ],
    
    );
1;
