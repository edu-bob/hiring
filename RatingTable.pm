# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use UserTable;
use CandidateTable;

%::RatingTable = (
	      table => "rating",
	      heading => "Ratings",
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
			      column => "rating",
			      heading => "Rating 0..10",
			      type => "float",
			      validators => [
					     [ 'emptyOK' ],
					     [ 'float' ],
					     [ 'range', [0, 10] ],
					     ],
			  },
			  {
			      column => "comment",
			      heading => "Short Comment",
			      type => "text",
			      width => "100",
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
