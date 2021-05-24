# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use DepartmentTable;
use OpeningCcTable;

%::OpeningTable = (
    table => "opening",
    heading => "Openings",
    label => "description",
    order => "priority,duedate,description",
    
    filters => [
	{
	    name => "active",
	    active => \&Opening::isActive,
	    activeSQL => \&Opening::isActiveSQL,
	},
    ],
    columns => [
	{
	    column => "id",
	    type => "pk",
	},
	{
	    column => "creation",
	    heading => "Created",
	    type => "datetime",
	},
	{
	    column => "number",
	    heading => "Req Number",
	    help => "The requisition number, obtained from corporate HR.",
	    type => "text",
	},
	{
	    column => "description",
	    heading => "Description",
	    help => "A short description of the job opening, or the job title.",
	    labels => \&Opening::menuLabel,
	    type => "text",
	},
#			       {
#				   column => "owner_id",
#				   heading => "Owner",
#				   type => "fk",
#				   values => {
#				       table => \%::UserTable,
#				       pk => "id",
#				       label => "name",
#				   },
#				   help => "The hiring manager.",
#			       },
	{
	    column => "url",
	    heading => "URL",
	    type => "url",
                                   help => "A full URL to the job description document for this opening.  The URL must refer to a standard HTML document without Microsoft Word change tracking enabled."
	},
	{
	    column => "status",
	    heading => "Status",
	    type => "enum",
	},
	{
	    column => "priority",
	    heading => "Priority",
	    type => "text",
	    help => "Hiring priority, used as a sort order in reports.",
	},
	{
	    column => "duedate",
	    heading => "Fill-by Date",
	    type => "date",
	},
	{
	    column => "department_id",
	    heading => "Department",
	    type => "fk",
	    values => {
		table => \%::DepartmentTable,
		pk => "id",
		label => "name",
	    },
	    help => "What department this requisition is in.",
	},
	{
	    column => "short_key",
	    heading => "Short Key",
	    type => "text",
	    help => "A short key for the position that may exist on e-mail submisions coming form the corporate web site.",
	},
    ],
    rels => [
	{
	    type => "N-N",
	    heading => "CC",
	    table => \%::OpeningCcTable,
	    column => ["opening_id","user_id"],
	    hashkey => "cc",
	    help => "Select users to be CC'd on changes",
	    widget => "Left/Right",
	    size => 5,
	},
	{
	    type => "N-N",
	    heading => "Action",
	    table => \%::OpeningActionTable,
	    column => ["opening_id","action_id"],
	    hashkey => "action",
	    help => "Select actions to allow on this opening",
	    widget => "Left/Right",
	},
	{
	    type => "N-N",
	    heading => "Evaluation Form",
	    table => \%::OpeningEvaluationTable,
	    column => ["opening_id","evaluation_id"],
	    hashkey => "evaluation",
	    help => "Select forms to allow on this opening",
	    widget => "Left/Right",
	}
    ],
    );

1;
