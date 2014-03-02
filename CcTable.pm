# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use UserTable;
use CandidateTable;

%::CcTable = (
			  table => "cc",
			  heading => "CC",
			  columns => [
						  {
							  column => "id",
							  heading => "Id",
							  type => "pk",
						  },
						  {
							  column => "candidate_id",
							  heading => "Candidate",
							  type => "fk",
							  values => {
								  table => \%::CandidateTable,
								  pk => "id",
								  label => "name",
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
