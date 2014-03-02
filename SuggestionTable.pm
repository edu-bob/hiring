# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use UserTable;

%::SuggestionTable = (
		       table => "suggestion",
		       heading => "Suggestions",
		       columns => [
				   {
				       column => "id",
				       heading => "Id",
				       type => "pk",
				   },
				   {
				       column => "creation",
				       heading => "Created",
				       type => "datetime",
				   },
				   {
				       column => "submitter_id",
				       heading => "Submitted By",
				       type => "fk",
				       values => {
					   table => \%::UserTable,
					   pk => "id",
					   label => "name",
				       },
				   },
				   {
				       column => "content",
				       heading => "Content",
				       type => "bigtext",
				   },
				   {
				       column => "status",
				       heading => "Status",
				       type => "enum",
				   },
				   {
				       column => "priority",
				       heading => "Priority",
				       type => "enum",
				   },
				   ],
		       );
1;
