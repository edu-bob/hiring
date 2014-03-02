# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use UserTable;
use OpeningTable;

%::OpeningCcTable = (
			  table => "opening_cc",
			  heading => "Opening CC",
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
							  column => "user_id",
							  heading => "User",
							  type => "fk",
							  values => {
								  table => \%::UserTable,
								  pk => "id",
								  label => "name",
							  },
						  },
						  ],
							  
			  );
1;
