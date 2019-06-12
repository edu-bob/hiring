# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use CandidateTable;
use InterviewSlotTable;

%::InterviewTable = (
		     table => "interview",
		     heading => "Interview",
		     order => "date",
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
				     column => "date",
				     heading => "Date",
				     type => "text",
				     validators => [
						    [ 'required' ],
						    ],
				 },
				 {
				     column => "purpose",
				     heading => "Purpose",
				     type => "text",
				     validators => [
						    [ 'required' ],
						    ],
				 },
				 {
				     column => "status",
				     heading => "Status",
				     type => "enum",
				 },
				 {
				     column => "note_interviewer",
				     heading => "Note to Interviewers",
				     type => "bigtext",
#				     rows=>12,
#				     columns=>80,
				 },
				 ],
		     rels => [
			      {
				  type => "1-N",
				  containment => 1,
				  table => \%::InterviewSlotTable,
				  column => "interview_id",
				  hashkey => "slots",
			      },
			      ],
		     );
1;
