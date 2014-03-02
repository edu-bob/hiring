# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use InterviewTable;
use InterviewPersonTable;

%::InterviewSlotTable = (
			 table => "interview_slot",
			 heading => "Interview Slot",
			 order => "time",
			 columns => [
				     {
					 column => "id",
					 heading => "Id",
					 type => "pk",
				     },
				     {
					 column => "interview_id",
					 heading => "Interview",
					 type => "fk",
					 values => {
					     table => \%::InterviewTable,
					     pk => "id",
					     label => "purpose",
					 },
				     },
				     {
					 column => "time",
					 heading => "Time",
					 type => "text",
				     },
				     {
					 column => "duration",
					 heading => "Duration",
					 type => "text",
				     },
				     {
					 column => "type",
					 heading => "Type",
					 type => "enum",
				     },
				     {
					 column => "location",
					 heading => "Location",
					 type => "text",
				     },
				     {
					 column => "topic",
					 heading => "Topic",
					 type => "text",
				     },
				     {
					 column => "hide",
					 heading => "Hide",
					 type => "text",
				     },
				     ],
			 rels => [
				      {
					  type => "1-N",
					  containment => '1',
					  table => \%::InterviewPersonTable,
					  column => "interview_slot_id",
					  hashkey => "persons",
				      },
				      ],
			 );

1;
