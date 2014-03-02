# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use CandidateTable;
use UserTable;


%::CommentTable = (
		   table => "comment",
		   heading => "Comments",
		   columns => [
			       {
				   column => "id",
				   heading => "Id",
				   type => "pk",
			       },
			       {
				   column => "creation",
				   heading => "Creation",
				   type => "datetime",
			       },
			       {
				   column => "comment",
				   heading => "Comment",
				   type => "bigtext",
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
			       ]
		   );
1;
