# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::ReferrerTypeTable = (
				   table => "referrer_type",
				   heading => "Referrer Types",
				   label => "name",
				   columns => [
							   {
								   column => "id",
								   type => "pk",
							   },
							   {
								   column => "name",
								   heading => "Name",
								   help => "Type of referrer.",
							   },
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
								   column => "department_id",
								   heading => "Department",
								   type => "fk",
								   values => {
									   table => \%::DepartmentTable,
									   pk => "id",
									   label => "name",
								   },
							   },
							   ],
				   );

1;
