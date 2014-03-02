# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use UserTable;
use InterviewTable;

%::InterviewPersonTable = (
			   table => "interview_person",
			   heading => "Interview x Person",
			   columns => [
				       {
					   column => "id",
					   heading => "ID",
					   type => "pk",
				       },
				       {
					   column => "interview_slot_id",
					   heading => "Interview Slot",
					   type => "fk",
					   values => {
					       table => \%::InterviewSlotTable,
					       pk => "id",
					       label => "time",
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
