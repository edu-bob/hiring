# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::DepartmentTable = (
					  table => "department",
					  heading => "Departments",
					  label => "name",
					  columns => [
								  {
									  column => "id",
									  type => "pk",
								  },
								  {
									  column => "name",
									  heading => "Department Full Name",
									  type => "text",
								  },
								  {
									  column => "abbrev",
									  heading => "Abbreviation",
									  type => "text",
								  },
								  ],
				);

1;
